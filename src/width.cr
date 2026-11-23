require "textseg"
require "./incb"

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

  # UAX #29 GB9c state: the segmentation shard does not implement GB9c, so the
  # conjunct pattern is tracked here. `Consonant` means a Consonant was seen and
  # is waiting for a Linker, `Linker` means the pattern is ready to join the
  # next Consonant.
  private enum ConjunctState
    None
    Consonant
    Linker
  end

  # Folds the Indic_Conjunct_Break classes of *codepoints* into *state*, the
  # same way github.com/clipperhouse/uax29's grapheme splitter updates its
  # GB9c state as it advances.
  private def self.fold_conjunct_state(state : ConjunctState, codepoints : Array(Int32)) : ConjunctState
    codepoints.each do |codepoint|
      if InCB.consonant?(codepoint)
        state = ConjunctState::Consonant
      elsif InCB.linker?(codepoint)
        state = ConjunctState::Linker unless state.none?
      elsif !InCB.extend?(codepoint)
        state = ConjunctState::None
      end
    end
    state
  end

  # Returns the exclusive end offset of the first cluster in *clusters*, joined
  # with the cluster that follows it while UAX #29 GB9c holds them together:
  #
  #   Consonant [Extend Linker]* Linker [Extend Linker]* x Consonant
  #
  # The shard breaks the pattern between a Linker and the following Consonant,
  # which splits Devanagari conjuncts such as "\u0938\u094d\u0924\u0947" into
  # "\u0938\u094d" and "\u0924\u0947". Linkers are only the six codepoints
  # Unicode assigns InCB=Linker to, so viramas of scripts without conjunct
  # clusters (Tamil, Kannada, Sinhala, Gurmukhi) keep their separate clusters.
  private def self.conjunct_cluster_end(clusters : Array(TextSegment::Grapheme::Cluster)) : Int32
    _from, to = clusters[0].positions
    state = fold_conjunct_state(ConjunctState::None, clusters[0].codepoints)
    index = 0

    while state.linker? && index + 1 < clusters.size
      following = clusters[index + 1]
      first = following.codepoints.first?
      break unless first && InCB.consonant?(first)

      index += 1
      _from, to = following.positions
      # GB9c restarts the pattern at the joined Consonant, so the rest of the
      # cluster is folded from `Consonant` rather than from the previous state.
      state = fold_conjunct_state(ConjunctState::Consonant, following.codepoints[1..])
    end

    to
  end

  # each_grapheme_cluster yields every grapheme cluster in *s* with the width it
  # occupies, using the same segmentation and the same ANSI handling as
  # [string_width]: escape sequences are skipped, and a cluster joined by an
  # Indic Linker absorbs the cluster that follows it (GB9c), so
  # "\u0938\u094d\u0924\u0947" is one cluster of width 2 rather than
  # "\u0938\u094d" + "\u0924\u0947".
  #
  # Consumers that need to walk a string and measure as they go (drawing a
  # StyledString, for example) should use this instead of a generic grapheme
  # iterator. Measuring with [string_width] but segmenting with a different
  # iterator makes the two disagree on conjuncts, and the terminal paints one
  # cell where the caller counted two.
  #
  # Summing the yielded widths gives [string_width] for the same string, and
  # the yielded clusters concatenate to `strip(s)`: escape bytes are not
  # yielded, since they occupy no cells.
  def self.each_grapheme_cluster(s : String, m : Method = Method::WcWidth, & : String, Int32 ->) : Nil
    bytes = s.to_slice
    pstate = ParserTransition::GroundState
    i = 0

    while i < bytes.size
      state, action = ParserTransition::Table.transition(pstate, bytes[i])
      if action == ParserTransition::PrintAction || state == ParserTransition::Utf8State
        cluster, width = first_grapheme_cluster(s.byte_slice(i, s.bytesize - i), m)
        break if cluster.empty?

        yield cluster, width
        i += cluster.bytesize
        pstate = ParserTransition::GroundState
        next
      end

      pstate = state
      i += 1
    end
  end

  private def self.first_grapheme_cluster(s : String, m : Method) : {String, Int32}
    return {"", 0} if s.empty?

    clusters = TextSegment.graphemes(s)
    return {"", 0} if clusters.empty?

    cluster_str = s.byte_slice(0, conjunct_cluster_end(clusters))
    width = m == Method::WcWidth ? wc_cluster_width(cluster_str) : DisplayWidth.grapheme_width(cluster_str)
    {cluster_str, width}
  end

  private def self.first_grapheme_cluster(bytes : Bytes, m : Method) : {Bytes, Int32}
    str = bytes_to_string(bytes)
    return {Bytes.empty, 0} if str.empty?

    clusters = TextSegment.graphemes(str)
    return {Bytes.empty, 0} if clusters.empty?

    cluster_bytes = bytes[0, conjunct_cluster_end(clusters)]
    width = m == Method::WcWidth ? wc_cluster_width(cluster_bytes) : DisplayWidth.grapheme_width(cluster_bytes)
    {cluster_bytes, width}
  end

  private def self.grapheme_cluster_width(cluster : TextSegment::Grapheme::Cluster) : Int32
    DisplayWidth.grapheme_width(cluster.str)
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
