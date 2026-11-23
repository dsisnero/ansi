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
