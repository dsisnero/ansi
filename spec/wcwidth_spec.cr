require "./spec_helper"

# Ported from x/ansi/wcwidth_test.go. The upstream test that sweeps every
# codepoint above the BMP is represented by a sample here; the table-driven
# cases below cover each zero-width category and the fallback widths.
describe "Ansi wcwidth helpers" do
  describe ".wc_cluster_width" do
    cases = [
      {"ascii", "a", 1, 1},
      {"combining acute", "é", 1, 1},
      {"devanagari conjunct", "स्ते", 2, 1},
      {"devanagari kssa", "क्ष", 2, 1},
      {"cjk", "世", 2, 2},
      {"emoji", "🌈", 2, 2},
      {"vs16", "⚠️", 1, 2},
      {"vs15", "☹︎", 1, 1},
      {"keycap", "1️⃣", 1, 2},
      {"zwj pair", "👨‍💻", 4, 2},
      {"zwj family", "👨‍👩‍👧‍👦", 8, 2},
      {"zwj flag", "🏳️‍🌈", 3, 2},
      {"skin tone", "👍🏽", 4, 2},
      {"regional indicators", "🇺🇸", 2, 2},
      {"halfwidth voiced mark", "ｶﾞ", 2, 1},
      {"c1 string", "\u009bx", 1, 1},
    ]

    cases.each do |name, input, wc_width, grapheme|
      it name do
        Ansi.wc_cluster_width(input).should eq wc_width
        Ansi.wc_cluster_width(input.to_slice).should eq wc_width
        Ansi.string_width_wc(input).should eq wc_width
        Ansi.string_width(input).should eq grapheme
      end
    end
  end

  describe ".wc_rune_width" do
    cases = [
      {"nul", 0x0000, 0},
      {"bell", 0x0007, 0},
      {"del", 0x007f, 0},
      {"c1 pad", 0x0080, 0},
      {"c1 csi", 0x009b, 0},
      {"c1 apc", 0x009f, 0},
      {"ascii", 0x0061, 1},
      {"latin1", 0x00e9, 1},
      {"combining acute", 0x0301, 0},
      {"devanagari virama", 0x094d, 0},
      {"devanagari vowel sign", 0x0947, 0},
      {"hebrew point", 0x05b0, 0},
      {"arabic fatha", 0x064e, 0},
      {"thai vowel", 0x0e34, 0},
      {"zwj", 0x200d, 0},
      {"vs15", 0xfe0e, 0},
      {"vs16", 0xfe0f, 0},
      {"enclosing keycap", 0x20e3, 0},
      {"cjk", 0x4e16, 2},
      {"hangul", 0xd55c, 2},
      {"halfwidth katakana", 0xff76, 1},
      {"emoji", 0x1f308, 2},
      {"skin tone modifier", 0x1f3fd, 2},
      {"regional indicator", 0x1f1fa, 1},
      {"musical symbol mark", 0x1d167, 0},
      {"musical symbol stem", 0x1d165, 0},
      {"variation selector supplement", 0xe0100, 0},
      {"tag character", 0xe0041, 0},
    ]

    cases.each do |name, codepoint, want|
      it name do
        Ansi.wc_rune_width(codepoint).should eq want
      end
    end
  end

  it "honors East Asian ambiguous widths" do
    condition = UnicodeCharWidth.default_condition
    previous = condition.east_asian
    condition.east_asian = true
    begin
      [0x00a1, 0x00b0, 0x00d7].each do |codepoint|
        Ansi.wc_rune_width(codepoint).should eq 2
      end
      Ansi.string_width_wc("¡°é").should eq 6
    ensure
      condition.east_asian = previous
    end
  end
end
