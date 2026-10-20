require "uniwidth"
require "unicode_width"

module Ansi
  def self.strip(s : String) : String
    bytes = s.to_slice
    buf = String::Builder.new
    ri = 0
    rw = 0
    pstate = ParserTransition::GroundState
    i = 0

    while i < bytes.size
      b = bytes[i]
      if pstate == ParserTransition::Utf8State
        buf.write_byte(b)
        ri += 1
        if ri < rw
          i += 1
          next
        end
        pstate = ParserTransition::GroundState
        ri = 0
        rw = 0
        i += 1
        next
      end

      state, action = ParserTransition::Table.transition(pstate, b)
      case action
      when ParserTransition::CollectAction
        if state == ParserTransition::Utf8State
          rw = utf8_byte_len(b)
          buf.write_byte(b)
          ri = 1
        end
      when ParserTransition::PrintAction, ParserTransition::ExecuteAction
        buf.write_byte(b)
      end

      pstate = state if pstate != ParserTransition::Utf8State
      i += 1
    end

    buf.to_s
  end

  def self.string_width(s : String) : Int32
    string_width(Method::GraphemeWidth, s)
  end

  def self.string_width_wc(s : String) : Int32
    string_width(Method::WcWidth, s)
  end

  def self.string_width(m : Method, s : String) : Int32
    return 0 if s.empty?

    bytes = s.to_slice
    pstate = ParserTransition::GroundState
    width = 0
    i = 0

    while i < bytes.size
      state, action = ParserTransition::Table.transition(pstate, bytes[i])
      if action == ParserTransition::PrintAction || state == ParserTransition::Utf8State
        if m == Method::WcWidth
          # Wcwidth sums codepoints, so where the cluster boundaries fall
          # makes no difference to the total. Skipping the segmentation is a
          # good deal cheaper.
          char, size = decode_rune(s, i)
          width += wc_rune_width(char.ord)
          i += size
          pstate = ParserTransition::GroundState
          next
        end

        cluster_bytes, w = first_grapheme_cluster(bytes[i, bytes.size - i], m)
        width += w
        advance = cluster_bytes.size
        advance = 1 if advance == 0
        i += advance
        pstate = ParserTransition::GroundState
        next
      end

      width += 1 if action == ParserTransition::PrintAction
      pstate = state
      i += 1
    end

    width
  end

  private def self.decode_rune(s : String, byte_index : Int32) : {Char, Int32}
    reader = Char::Reader.new(s, byte_index)
    char = reader.current_char
    reader.next_char
    {char, reader.pos - byte_index}
  end

  private def self.utf8_byte_len(b : UInt8) : Int32
    if b <= 0x7f
      1
    elsif b >= 0xc0 && b <= 0xdf
      2
    elsif b >= 0xe0 && b <= 0xef
      3
    elsif b >= 0xf0 && b <= 0xf7
      4
    else
      -1
    end
  end

  private def self.bytes_to_string(bytes : Bytes) : String
    String.new(bytes, "UTF-8", :skip)
  end

  private def self.first_char_from_bytes(bytes : Bytes) : Char?
    str = bytes_to_string(bytes)
    str.each_char do |char|
      return char
    end
    nil
  end

  # UAX #29 GB9c conjunct clusters for the major Indic scripts. The text
  # segmentation shard does not merge a consonant + virama with the following
  # consonant, so merge them here.
  private INDIC_VIRAMAS = [
    0x094d, # Devanagari
    0x09cd, # Bengali
    0x0a4d, # Gurmukhi
    0x0acd, # Gujarati
    0x0b4d, # Oriya
    0x0bcd, # Tamil
    0x0c4d, # Telugu
    0x0ccd, # Kannada
    0x0d4d, # Malayalam
    0x0dca, # Sinhala
  ] of Int32

  private def self.first_grapheme_cluster(s : String, m : Method) : {String, Int32}
    return {"", 0} if s.empty?

    clusters = TextSegment.graphemes(s)
    return {"", 0} if clusters.empty?

    index = 0
    cluster = clusters[index]
    from, to = cluster.positions
    cps = cluster.codepoints
    last = cps.last?
    while last && INDIC_VIRAMAS.includes?(last) && index + 1 < clusters.size
      index += 1
      following = clusters[index]
      _following_from, following_to = following.positions
      to = following_to
      cps = following.codepoints
      last = cps.last?
    end

    cluster_str = s.byte_slice(from, to - from)
    width = m == Method::WcWidth ? wc_cluster_width(cluster_str) : grapheme_cluster_width(cps)
    {cluster_str, width}
  end

  private def self.first_grapheme_cluster(bytes : Bytes, m : Method) : {Bytes, Int32}
    str = bytes_to_string(bytes)
    return {Bytes.empty, 0} if str.empty?

    clusters = TextSegment.graphemes(str)
    return {Bytes.empty, 0} if clusters.empty?

    index = 0
    cluster = clusters[index]
    _from, to = cluster.positions
    cps = cluster.codepoints
    last = cps.last?
    while last && INDIC_VIRAMAS.includes?(last) && index + 1 < clusters.size
      index += 1
      following = clusters[index]
      _following_from, following_to = following.positions
      to = following_to
      cps = following.codepoints
      last = cps.last?
    end

    cluster_bytes = bytes[0, to]
    width = m == Method::WcWidth ? wc_cluster_width(cluster_bytes) : grapheme_cluster_width(cps)
    {cluster_bytes, width}
  end

  private def self.grapheme_cluster_width(cluster : TextSegment::Grapheme::Cluster) : Int32
    grapheme_cluster_width(cluster.codepoints)
  end

  private def self.grapheme_cluster_width(cps : Array(Int32)) : Int32
    regional_count = cps.count { |codepoint| regional_indicator?(codepoint) }
    return ((regional_count + 1) // 2) * 2 if regional_count > 0
    return 2 if emoji_presentation?(cps)

    cps.each do |codepoint|
      next if codepoint < 0x20 || (codepoint >= 0x7f && codepoint <= 0x9f)
      next if Unicode.zero_width?(codepoint)
      next if legacy_zero_width?(codepoint)

      width = UnicodeWidth.width(codepoint.chr)
      return width > 0 ? width : 1
    end
    0
  end

  private def self.emoji_presentation?(cps : Array(Int32)) : Bool
    return true if cps.size > 1 && cps.includes?(0x20e3) # enclosing keycap
    return true if cps.size > 1 && cps.includes?(0xfe0f) # VS16 emoji presentation
    return true if cps.any? { |codepoint| codepoint >= 0xe0020 && codepoint <= 0xe007f }
    cps.includes?(0x200d) && cps.any? { |codepoint| emoji_codepoint?(codepoint) }
  end

  private def self.regional_indicator?(codepoint : Int32) : Bool
    codepoint >= 0x1f1e6 && codepoint <= 0x1f1ff
  end

  private def self.emoji_codepoint?(codepoint : Int32) : Bool
    table = UnicodeCharWidth.emoji_table
    return false if table.empty?
    return false if codepoint < table[0].first

    bot = 0
    top = table.size - 1
    while top >= bot
      mid = (bot + top) >> 1
      range = table[mid]
      if range[1] < codepoint
        bot = mid + 1
      elsif range[0] > codepoint
        top = mid - 1
      else
        return true
      end
    end
    false
  end

  private def self.bytes_contains_any(bytes : Bytes, breakpoints : String) : Bool
    return false if breakpoints.empty?
    str = bytes_to_string(bytes)
    str.each_char do |char|
      return true if breakpoints.includes?(char)
    end
    false
  end

  private def self.rune_contains_any(r : Char, s : String) : Bool
    s.each_char do |char|
      return true if char == r
    end
    false
  end
end

module UnicodeCharWidth
  def self.emoji_table
    emoji
  end
end
