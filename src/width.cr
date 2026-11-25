require "./gcb"
require "./grapheme"

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
    walk = ClusterWalk.new(bytes, m)

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

        cluster_bytes, w = next_cluster(walk, i)
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
    # No validation: a String can carry the raw bytes, and filtering them
    # (`:skip`) would make a yielded cluster disagree with its measured width on
    # invalid input.
    String.new(bytes)
  end

  private def self.first_char_from_bytes(bytes : Bytes) : Char?
    str = bytes_to_string(bytes)
    str.each_char do |char|
      return char
    end
    nil
  end

  # UAX #29 only extends a cluster with Extend, ZWJ, SpacingMark, and the Indic
  # conjunct, extended pictographic, and regional indicator continuations, none
  # of which is ASCII (the one ASCII-pair rule, CR x LF, needs a CR first). So a
  # printable ASCII byte followed by another ASCII byte is a one-cell cluster of
  # its own. That is the same hot path github.com/clipperhouse/uax29's iterator
  # takes, and it keeps ASCII (the common case for a document) clear of the
  # segmenter entirely.
  private def self.ascii_cluster?(bytes : Bytes, i : Int32) : Bool
    byte = bytes[i]
    return false unless 0x20 <= byte <= 0x7e

    following = i + 1
    following >= bytes.size || bytes[following] < 0x80
  end

  # State for [next_cluster]: the buffer being walked and how to measure a
  # cluster. Clusters are found on demand by [Grapheme.cluster_end], which reads
  # one code point at a time, so the walk is linear and needs no lookahead state.
  class ClusterWalk
    getter bytes : Bytes
    getter method : Method
    getter? incb : Bool

    def initialize(@bytes : Bytes, @method : Method, @incb : Bool = true)
    end
  end

  # Returns the cluster starting at *offset* and the width it occupies.
  #
  # Every walker (width, truncate, wrap) asks for increasing offsets, and the
  # splitter restarts at *offset* exactly as Go's per-cluster
  # `FirstGraphemeCluster` does.
  def self.next_cluster(walk : ClusterWalk, offset : Int32) : {Bytes, Int32}
    first_grapheme_cluster(walk.bytes, offset, walk.method, walk.incb?)
  end

  private def self.cluster_width(cluster_bytes : Bytes, m : Method) : Int32
    m == Method::WcWidth ? wc_cluster_width(cluster_bytes) : DisplayWidth.grapheme_width(cluster_bytes)
  end

  # Reads the grapheme cluster that starts at *offset*.
  #
  # The walkers used to hand this method `bytes[i, bytes.size - i]`, which
  # copies the whole remaining string for every cluster: walking a 99 KB
  # katakana string took ~4.8 s in `each_grapheme_cluster`, ~1.6 s in
  # `cut`/`truncate` and ~0.8 s in `string_width`. Reading from the offset
  # copies only the cluster, so every walk is O(n).
  private def self.first_grapheme_cluster(bytes : Bytes, offset : Int32, m : Method, incb : Bool = true) : {Bytes, Int32}
    return {Bytes.empty, 0} if offset < 0 || offset >= bytes.size

    # Printable ASCII is one cell under both methods, so no width lookup is
    # needed here either.
    return {bytes[offset, 1], 1} if ascii_cluster?(bytes, offset)

    stop = Grapheme.cluster_end(bytes, offset, incb)
    return {Bytes.empty, 0} if stop <= offset

    cluster_bytes = bytes[offset, stop - offset]
    {cluster_bytes, cluster_width(cluster_bytes, m)}
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
  def self.each_grapheme_cluster(s : String, m : Method = Method::WcWidth, incb : Bool = true, & : String, Int32 ->) : Nil
    bytes = s.to_slice
    pstate = ParserTransition::GroundState
    i = 0
    walk = ClusterWalk.new(bytes, m, incb)

    while i < bytes.size
      state, action = ParserTransition::Table.transition(pstate, bytes[i])
      if action == ParserTransition::PrintAction || state == ParserTransition::Utf8State
        cluster_bytes, width = next_cluster(walk, i)
        break if cluster_bytes.empty?

        yield bytes_to_string(cluster_bytes), width
        i += cluster_bytes.size
        pstate = ParserTransition::GroundState
        next
      end

      pstate = state
      i += 1
    end
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
