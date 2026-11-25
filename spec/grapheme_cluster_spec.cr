require "./spec_helper"

# `each_grapheme_cluster` exposes the segmentation the width functions already
# use internally, so a consumer cannot end up measuring a string one way and
# iterating it another. Ultraviolet's StyledString needs exactly that: it walks
# clusters and measures each one.
#
# Prior to this API the only public entry point was `string_width`, and a
# consumer that segmented with a plain Unicode grapheme iterator split Indic
# conjuncts into separate clusters (GB9c): "स्ते" is one cluster that the
# terminal prints in one cell, not "स्" + "ते".
private def grapheme_clusters(s : String, method : Ansi::Method = Ansi::Method::WcWidth) : Array(String)
  clusters = [] of String
  Ansi.each_grapheme_cluster(s, method) { |cluster, _width| clusters << cluster }
  clusters
end

private def grapheme_cluster_widths(s : String, method : Ansi::Method = Ansi::Method::WcWidth) : Hash(String, Int32)
  widths = {} of String => Int32
  Ansi.each_grapheme_cluster(s, method) { |cluster, width| widths[cluster] = width }
  widths
end

private def grapheme_cluster_width_sum(s : String, method : Ansi::Method = Ansi::Method::WcWidth) : Int32
  total = 0
  Ansi.each_grapheme_cluster(s, method) { |_cluster, width| total += width }
  total
end

describe "Ansi.each_grapheme_cluster" do
  it "merges virama-joined conjuncts into one cluster" do
    grapheme_clusters("स्ते").should eq(["स्ते"])
  end

  it "keeps ordinary grapheme clusters separate" do
    grapheme_clusters("a👋b").should eq(["a", "👋", "b"])
  end

  it "reports the width each cluster would occupy" do
    widths = grapheme_cluster_widths("स्ते👋")

    widths["स्ते"].should eq(2)
    widths["👋"].should eq(2)
  end

  it "measures a cluster the same way string_width measures the whole string" do
    total = 0
    Ansi.each_grapheme_cluster("स्ते क्ष त्र ज्ञ") { |_cluster, width| total += width }

    total.should eq(Ansi.string_width_wc("स्ते क्ष त्र ज्ञ"))
  end

  it "yields nothing for an empty string" do
    count = 0
    Ansi.each_grapheme_cluster("") { |_cluster, _width| count += 1 }

    count.should eq(0)
  end

  # The expected clusters and widths come from the vendored Go dependency
  # github.com/clipperhouse/uax29/v2, which implements UAX #29 GB9c:
  #
  #   Consonant [Extend Linker]* Linker [Extend Linker]* x Consonant
  describe "UAX #29 GB9c conjunct boundaries" do
    {
      # A Linker joins the following Consonant.
      "क्ष"       => ["क्ष"],
      "क्क्ष"     => ["क्क्ष"],
      "क़्क"      => ["क़्क"],
      "क्षत्रज्ञ" => ["क्ष", "त्र", "ज्ञ"],
      # ZWJ has Indic_Conjunct_Break=Extend, ZWNJ does not, so only ZWJ holds
      # the pattern together.
      "क्\u200Dष" => ["क्\u200Dष"],
      "क्\u200Cष" => ["क्\u200C", "ष"],
      # GB9c needs a Consonant before the Linker and one after it, so a
      # Linker followed by anything else does not join.
      "क् क"    => ["क्", " ", "क"],
      "क्A"     => ["क्", "A"],
      "क्👋"     => ["क्", "👋"],
      "\u094Dक" => ["\u094D", "क"],
      # Only the six scripts Unicode assigns Indic_Conjunct_Break=Linker to
      # form conjunct clusters. Tamil, Kannada, Sinhala, and Gurmukhi viramas
      # end a cluster instead of extending it.
      "க்ஷ"  => ["க்", "ஷ"],
      "ಕ್ಷ"  => ["ಕ್", "ಷ"],
      "ක්ෂ"  => ["ක්", "ෂ"],
      "ਕ੍ਸ਼" => ["ਕ੍", "ਸ਼"],
      # Bengali, Gujarati, Oriya, Telugu, and Malayalam do form conjuncts.
      "ক্ষ"  => ["ক্ষ"],
      "સ્તે" => ["સ્તે"],
      "କ୍ଷ"  => ["କ୍ଷ"],
      "క్ష"  => ["క్ష"],
      "ക്ഷ"  => ["ക്ഷ"],
    }.each do |input, expected|
      it "segments #{input.inspect} as #{expected.inspect}" do
        grapheme_clusters(input).should eq(expected)
      end
    end
  end

  describe "ANSI escape sequences" do
    it "skips escape sequences instead of yielding their bytes" do
      grapheme_clusters("\e[31mस्ते\e[0m").should eq(["स्ते"])
    end

    it "reports the width of the text, matching string_width" do
      grapheme_cluster_width_sum("\e[31mस्ते\e[0m").should eq(2)
      grapheme_cluster_width_sum("\e[31mस्ते\e[0m").should eq(Ansi.string_width_wc("\e[31mस्ते\e[0m"))
    end
  end

  describe "agreement with string_width" do
    {
      "",
      "abc",
      "a👋b",
      "स्ते क्ष त्र ज्ञ",
      "नमस्ते",
      "क् क",
      "க்ஷ",
      "👨‍👩‍👧‍👦",
      "🇯🇵",
      "e\u0301",
      "\e[38;2;249;38;114mfoo\e[0m",
      "\e[31m👨‍👩‍👦\e[m",
      "\x9b38;5;1mhello\x9bm",
      "hello\nworld",
    }.each do |input|
      it "sums to string_width for #{input.inspect}" do
        grapheme_cluster_width_sum(input, Ansi::Method::WcWidth)
          .should eq(Ansi.string_width_wc(input))
        grapheme_cluster_width_sum(input, Ansi::Method::GraphemeWidth)
          .should eq(Ansi.string_width(input))
      end
    end
  end
end

# `first_grapheme_cluster` used to hand the whole remaining string to
# `TextSegment.graphemes` for every cluster, so walking a string cost O(n²):
# 475 bytes took 14 ms, 1.9 KB took 477 ms and 3.8 KB took 3.5 s. Consumers that
# measure as they draw (`StyledString`) and the input decoders pay that per
# frame or per read, so the segmentation must only look at the cluster it
# needs.
describe "grapheme cluster segmentation cost" do
  # Long enough for the quadratic shape to dominate (3000 clusters), short
  # enough to stay instant when linear. The bound is ~60x the linear cost and
  # ~12x below the quadratic one on the machine this was written on.
  bounded = "héllo wörld 😃 " * 200

  it "segments a long string in linear time" do
    elapsed = Time.measure do
      Ansi.each_grapheme_cluster(bounded) { |_cluster, _width| }
    end
    elapsed.should be < 400.milliseconds
  end

  it "decodes a long buffer in linear time" do
    bytes = bounded.to_slice
    elapsed = Time.measure do
      remaining = bytes
      while remaining.size > 0
        _seq, _width, taken, _state = Ansi.decode_sequence(remaining, 0_u8)
        break if taken <= 0
        remaining = remaining[taken, remaining.size - taken]
      end
    end
    elapsed.should be < 400.milliseconds
  end

  # `Ansi.string_width` is the entry point the quadratic behaviour was reported
  # against, and it pays the per-cluster cost for every printable byte, so an
  # ASCII document is the worst case: 8 000 characters took ~50 s before the
  # fix. Printable ASCII cannot start a multi-code-point cluster, so the ASCII
  # hot path keeps this near a millisecond while the general path still
  # segments.
  it "measures a long ASCII string without segmenting every byte" do
    elapsed = Time.measure do
      Ansi.string_width("a" * 8_000).should eq(8_000)
    end
    elapsed.should be < 100.milliseconds
  end

  # Every caller passed `bytes[i, bytes.size - i]` to `first_grapheme_cluster`,
  # so the string walkers still copied the whole remaining suffix once per
  # cluster and stayed quadratic on non-ASCII text: a 99 KB katakana string
  # took ~4.8 s in `each_grapheme_cluster`, ~1.6 s in `cut`/`truncate` and
  # ~0.8 s in `string_width`. Reading the cluster from its offset keeps every
  # walk O(n), so the same work must now finish in tens of milliseconds.
  wide = "あ" * 33_000 # ~99 KB, no ASCII fast path.

  it "walks a long non-ASCII string in linear time" do
    count = 0
    elapsed = Time.measure do
      Ansi.each_grapheme_cluster(wide) { |_cluster, _width| count += 1 }
    end
    count.should eq(33_000)
    elapsed.should be < 500.milliseconds
  end

  it "measures and slices a long non-ASCII string in linear time" do
    elapsed = Time.measure do
      Ansi.string_width(wide).should eq(66_000)
      Ansi.cut(wide, 0, 80).should_not be_empty
      Ansi.truncate(wide, 80, "…").should_not be_empty
      Ansi.wordwrap(wide, 80, "").should_not be_empty
    end
    elapsed.should be < 500.milliseconds
  end

  # The segmentation must not change while it gets cheaper: a cluster longer
  # than the lookahead window, and clusters that only a full UAX #29 pass gets
  # right.
  it "keeps segmentation exact for clusters longer than the window" do
    grapheme_clusters("👨‍👩‍👧‍👦a").should eq(["👨‍👩‍👧‍👦", "a"])
    grapheme_clusters("🏳️‍🌈🏴󠁧󠁢󠁳󠁣󠁴󠁿z").should eq(["🏳️‍🌈", "🏴󠁧󠁢󠁳󠁣󠁴󠁿", "z"])
    grapheme_clusters("स्तेabc").should eq(["स्ते", "a", "b", "c"])
    grapheme_clusters("각z").should eq(["각", "z"])
    grapheme_clusters("e\u0301e\u0301").should eq(["e\u0301", "e\u0301"])
    # Control bytes occupy no cells, so the iterator does not yield them.
    grapheme_clusters("\r\nx").should eq(["x"])
    grapheme_clusters("🇯🇵🇺🇸").should eq(["🇯🇵", "🇺🇸"])
  end

  # The ASCII hot path must not cut a cluster that an ASCII byte starts: a
  # combining mark or a spacing mark after ASCII still joins it, while a control
  # byte still ends it.
  it "keeps ASCII clusters exact next to non-ASCII code points" do
    grapheme_clusters("a\u0301b").should eq(["a\u0301", "b"])
    grapheme_clusters("a\u0903b").should eq(["a\u0903", "b"])
    grapheme_clusters("a1b2").should eq(["a", "1", "b", "2"])
    grapheme_clusters("a\tb").should eq(["a", "b"])
    Ansi.string_width("a\u0301").should eq(1)
    Ansi.string_width_wc("a\u0301").should eq(1)
    Ansi.string_width("a1b2").should eq(4)
    Ansi.string_width_wc("a1b2").should eq(4)
  end
end
