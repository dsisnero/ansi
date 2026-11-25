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

  # Returns the cluster bounds of *clusters*, joining each cluster with the one
  # that follows it while UAX #29 GB9c holds them together:
  #
  #   Consonant [Extend Linker]* Linker [Extend Linker]* x Consonant
  #
  # The segmentation shard breaks the pattern between a Linker and the following
  # Consonant, which splits Devanagari conjuncts such as "\u0938\u094d\u0924\u0947"
  # into "\u0938\u094d" and "\u0924\u0947". Linkers are only the six codepoints
  # Unicode assigns InCB=Linker to, so viramas of scripts without conjunct
  # clusters (Tamil, Kannada, Sinhala, Gurmukhi) keep their separate clusters.
  private def self.merged_cluster_bounds(clusters : Array(TextSegment::Grapheme::Cluster)) : Array(Tuple(Int32, Int32))
    bounds = Array(Tuple(Int32, Int32)).new(clusters.size)
    index = 0

    while index < clusters.size
      from, to = clusters[index].positions
      state = fold_conjunct_state(ConjunctState::None, clusters[index].codepoints)

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

      bounds << {from, to}
      index += 1
    end

    bounds
  end

  # Returns the exclusive end offset of the first cluster in *clusters*, joined
  # with the cluster that follows it while UAX #29 GB9c holds them together.
  private def self.conjunct_cluster_end(clusters : Array(TextSegment::Grapheme::Cluster)) : Int32
    bounds = merged_cluster_bounds(clusters)
    bounds.empty? ? 0 : bounds[0][1]
  end

  # Bytes segmented per `TextSegment.graphemes` call when walking a long run.
  #
  # The segmenter costs ~10 µs per call no matter how short the input is (it
  # builds two arrays and a char->byte index), so segmenting one cluster at a
  # time made every walker pay that per cluster: 33 000 katakana clusters cost
  # ~400 ms in `string_width` and ~1.6 s in `cut`, however cheap the segmentation
  # itself had become. Chunking amortises the call: 256 bytes holds ~85 CJK code
  # points and ~256 ASCII ones.
  SEGMENT_CHUNK_BYTES = 128

  # State for [next_cluster]: the buffer being walked and the cluster bounds
  # already segmented from it. A walker must ask for increasing offsets, which
  # every walker in this shard does.
  class ClusterWalk
    getter bytes : Bytes
    getter method : Method
    property bounds : Array(Tuple(Int32, Int32))
    property index : Int32
    # Set when the next refill should start from the small single-cluster
    # window instead of a full chunk: after a control, the chunk the walk was
    # sharing is dropped, and `textseg` is quadratic in the window's code points,
    # so a control-heavy stream would otherwise pay a chunk-sized segmentation
    # per control.
    property? narrow : Bool

    def initialize(@bytes : Bytes, @method : Method)
      @bounds = [] of Tuple(Int32, Int32)
      @index = 0
      @narrow = false
    end
  end

  # Returns the cluster starting at *offset* and the width it occupies, sharing
  # the segmentation of a whole chunk between consecutive calls.
  def self.next_cluster(walk : ClusterWalk, offset : Int32) : {Bytes, Int32}
    bytes = walk.bytes
    return {Bytes.empty, 0} if offset < 0 || offset >= bytes.size

    # A control code point is always a cluster of its own: GB4/GB5 outrank every
    # joining rule, including GB9b `Prepend x Any`, and `textseg` also loses its
    # state behind one (see `control_tail?`). It occupies no cells, so take it
    # straight from the buffer, drop the shared bounds, and let the next cluster
    # be segmented from its own start.
    if (length = control_length(bytes, offset)) > 0
      walk.bounds = [] of Tuple(Int32, Int32)
      walk.index = 0
      walk.narrow = true
      cluster_bytes = bytes[offset, length]
      return {cluster_bytes, cluster_width(cluster_bytes, walk.method)}
    end

    # Printable ASCII followed by ASCII is a one-cell cluster of its own (see
    # `ascii_cluster?`), which keeps ASCII documents away from the segmenter.
    return {bytes[offset, 1], 1} if ascii_cluster?(bytes, offset)

    # Malformed bytes have no defined grapheme properties, so the segmenter's
    # chunk state is not trustworthy across them: measure this cluster from its
    # own window (the pre-`ClusterWalk` behaviour) and drop the shared bounds.
    if decode_codepoint(bytes, offset).last == 0
      walk.bounds = [] of Tuple(Int32, Int32)
      walk.index = 0
      walk.narrow = true
      return first_grapheme_cluster(bytes, offset, walk.method)
    end

    if walk.index >= walk.bounds.size || walk.bounds[walk.index][0] != offset
      refill_bounds(walk, offset)
    end

    if walk.index < walk.bounds.size && walk.bounds[walk.index][0] == offset
      _from, to = walk.bounds[walk.index]
      cluster_bytes = bytes[offset, to - offset]
      walk.index += 1
      # `textseg` replaces its property state with `Any` after CR, LF and the
      # control code points (its GB3/GB4 fallback outranks the property
      # transitions), so bounds segmented past a control are not the boundaries a
      # pass anchored at the next cluster start would find: regional indicator
      # pairs stop pairing, Prepend stops joining, and an Extend joins a control.
      # Drop the shared bounds so the next call re-anchors; a fresh segmentation
      # is what Go's per-cluster `FirstGraphemeCluster` does, and controls are
      # rare in terminal text.
      if control_tail?(cluster_bytes)
        walk.bounds = [] of Tuple(Int32, Int32)
        walk.index = 0
        walk.narrow = true
      end
      return {cluster_bytes, cluster_width(cluster_bytes, walk.method)}
    end

    # Malformed input can leave the segmenter with no cluster at *offset* (a
    # truncated multi-byte sequence, for example). Measure that one from its own
    # window instead of re-anchoring on the same offset forever; an empty result
    # is the caller's signal to advance one byte.
    walk.bounds = [] of Tuple(Int32, Int32)
    walk.index = 0
    first_grapheme_cluster(bytes, offset, walk.method)
  end

  # Number of continuation bytes a UTF-8 lead byte introduces, or 0 when the
  # byte cannot start a well-formed sequence (continuation, overlong lead, or
  # outside the Unicode range).
  private def self.utf8_continuations(lead : UInt8) : Int32
    case lead
    when 0xc2..0xdf then 1
    when 0xe0..0xef then 2
    when 0xf0..0xf4 then 3
    else                 0
    end
  end

  # Smallest code point a sequence with *continuations* continuation bytes can
  # encode; anything lower is an overlong encoding.
  private def self.utf8_minimum(continuations : Int32) : Int32
    case continuations
    when 1 then 0x80
    when 2 then 0x800
    else        0x10000
    end
  end

  private def self.decode_payload(bytes : Bytes, offset : Int32, continuations : Int32) : Int32
    case continuations
    when 1
      ((bytes[offset] & 0x1f).to_i32 << 6) | (bytes[offset + 1] & 0x3f).to_i32
    when 2
      ((bytes[offset] & 0x0f).to_i32 << 12) |
        ((bytes[offset + 1] & 0x3f).to_i32 << 6) |
        (bytes[offset + 2] & 0x3f).to_i32
    else
      ((bytes[offset] & 0x07).to_i32 << 18) |
        ((bytes[offset + 1] & 0x3f).to_i32 << 12) |
        ((bytes[offset + 2] & 0x3f).to_i32 << 6) |
        (bytes[offset + 3] & 0x3f).to_i32
    end
  end

  # Decodes the UTF-8 code point that starts at *offset* inside `bytes[0, limit)`,
  # returning `{codepoint, byte_length}`, or `{0, 0}` when the sequence is
  # incomplete, overlong or malformed. Hand-rolled because the callers run per
  # cluster; strict, because a lenient decode would read a lone continuation byte
  # as a control.
  private def self.decode_codepoint(bytes : Bytes, offset : Int32, limit : Int32 = bytes.size) : {Int32, Int32}
    return {0, 0} if offset < 0 || offset >= limit

    lead = bytes[offset]
    return {lead.to_i32, 1} if lead < 0x80

    continuations = utf8_continuations(lead)
    return {0, 0} if continuations == 0 || offset + continuations >= limit

    (1..continuations).each do |i|
      return {0, 0} if (bytes[offset + i] & 0xc0) != 0x80
    end

    codepoint = decode_payload(bytes, offset, continuations)
    # Overlong encodings, surrogates and out-of-range code points never look
    # like a control.
    return {0, 0} if codepoint < utf8_minimum(continuations) || codepoint > 0x10ffff
    return {0, 0} if codepoint >= 0xd800 && codepoint <= 0xdfff

    {codepoint, continuations + 1}
  end

  # CR, LF, DEL and the C0/C1 controls never advance the cursor.
  private def self.control_codepoint?(codepoint : Int32) : Bool
    codepoint < 0x20 || codepoint == 0x7f || (0x80 <= codepoint <= 0x9f)
  end

  # Byte length of the control code point at *offset*, or 0 when the code point
  # there is not a control.
  private def self.control_length(bytes : Bytes, offset : Int32) : Int32
    codepoint, length = decode_codepoint(bytes, offset)
    length > 0 && control_codepoint?(codepoint) ? length : 0
  end

  # True when *cluster* ends with CR, LF, DEL, or a C0/C1 control code point.
  private def self.control_tail?(cluster : Bytes) : Bool
    size = cluster.size
    return false if size == 0

    start = size - 1
    while start > 0 && (cluster[start] & 0xc0) == 0x80
      start -= 1
    end

    codepoint, length = decode_codepoint(cluster, start)
    length > 0 && start + length == size && control_codepoint?(codepoint)
  end

  # Segments the chunk that starts at *offset*, keeping every bound that the
  # window can vouch for. A bound is trusted when the code point after the
  # cluster is inside the window, or when the window already reaches the end of
  # the buffer (a cluster cannot be cut short then).
  private def self.refill_bounds(walk : ClusterWalk, offset : Int32) : Nil
    bytes = walk.bytes
    remaining = bytes.size - offset
    first_window = walk.narrow? ? FIRST_CLUSTER_WINDOW : SEGMENT_CHUNK_BYTES
    window = Math.min(remaining, first_window)

    loop do
      clusters = TextSegment.graphemes(bytes_to_string(bytes[offset, window]))
      bounds = [] of Tuple(Int32, Int32)

      merged_cluster_bounds(clusters).each do |(from, to)|
        break unless window == remaining || to + FIRST_CLUSTER_LOOKAHEAD <= window
        bounds << {offset + from, offset + to}
      end

      unless bounds.empty?
        walk.bounds = bounds
        walk.index = 0
        walk.narrow = false
        return
      end

      if window == remaining
        # Nothing usable came back (a truncated sequence, for example): drop the
        # old bounds so the walk cannot spin on them. `next_cluster` then measures
        # this one cluster from its own window.
        walk.bounds = [] of Tuple(Int32, Int32)
        walk.index = 0
        return
      end

      window = Math.min(remaining, window * 2)
    end
  end

  private def self.cluster_width(cluster_bytes : Bytes, m : Method) : Int32
    m == Method::WcWidth ? wc_cluster_width(cluster_bytes) : DisplayWidth.grapheme_width(cluster_bytes)
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
    walk = ClusterWalk.new(bytes, m)

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

  # A cluster boundary only depends on the characters around it, so the first
  # cluster can be found from a short prefix. Handing `TextSegment.graphemes`
  # the whole remaining string on every call made walking a string quadratic:
  # 475 bytes took 14 ms, 1.9 KB took 477 ms and 3.8 KB took 3.5 s, which
  # `string_width`, `each_grapheme_cluster` and the input decoders all paid per
  # call. Clusters are a few code points in practice, so the window starts small
  # and doubles for the rare cluster that is longer (a long ZWJ emoji sequence,
  # for example).
  FIRST_CLUSTER_WINDOW = 32

  # A boundary is only trusted when this many bytes of the window follow it: a
  # UTF-8 code point is at most four bytes, so the character after the cluster
  # is complete inside the window and the boundary cannot differ from the one a
  # full-string pass would find.
  FIRST_CLUSTER_LOOKAHEAD = 4

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

  # Reads the grapheme cluster that starts at *offset*.
  #
  # The walkers used to hand this method `bytes[i, bytes.size - i]`, which
  # copies the whole remaining string for every cluster: walking a 99 KB
  # katakana string took ~4.8 s in `each_grapheme_cluster`, ~1.6 s in
  # `cut`/`truncate` and ~0.8 s in `string_width`. Reading from the offset
  # copies only the cluster, so every walk is O(n).
  private def self.first_grapheme_cluster(bytes : Bytes, offset : Int32, m : Method) : {Bytes, Int32}
    return {Bytes.empty, 0} if offset < 0 || offset >= bytes.size

    # Printable ASCII is one cell under both methods, so no width lookup is
    # needed here either.
    return {bytes[offset, 1], 1} if ascii_cluster?(bytes, offset)

    remaining = bytes.size - offset
    window = Math.min(remaining, FIRST_CLUSTER_WINDOW)
    loop do
      clusters = TextSegment.graphemes(bytes_to_string(bytes[offset, window]))
      stop = clusters.empty? ? 0 : conjunct_cluster_end(clusters)
      if window == remaining || stop + FIRST_CLUSTER_LOOKAHEAD <= window
        return {Bytes.empty, 0} if stop == 0

        cluster_bytes = bytes[offset, stop]
        return {cluster_bytes, cluster_width(cluster_bytes, m)}
      end
      window = Math.min(remaining, window * 2)
    end
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
