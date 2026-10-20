require "./spec_helper"

# Ported from x/ansi/method_test.go.
describe "Ansi::Method#string_width" do
  cases = [
    {"empty string wcwidth", Ansi::Method::WcWidth, "", 0},
    {"empty string grapheme width", Ansi::Method::GraphemeWidth, "", 0},
    {"ascii wcwidth", Ansi::Method::WcWidth, "hello", 5},
    {"ascii grapheme width", Ansi::Method::GraphemeWidth, "hello", 5},
    {"ansi wcwidth", Ansi::Method::WcWidth, "\e[31mred\e[0m", 3},
    {"ansi grapheme width", Ansi::Method::GraphemeWidth, "\e[31mred\e[0m", 3},
    {"wide chars wcwidth", Ansi::Method::WcWidth, "コンニチハ", 10},
    {"wide chars grapheme width", Ansi::Method::GraphemeWidth, "コンニチハ", 10},
    {"emoji wcwidth", Ansi::Method::WcWidth, "😀", 2},
    {"emoji grapheme width", Ansi::Method::GraphemeWidth, "😀", 2},
    {"flag emoji wcwidth", Ansi::Method::WcWidth, "🏳️‍🌈", 3},
    {"flag emoji grapheme width", Ansi::Method::GraphemeWidth, "🏳️‍🌈", 2},
    {"devanagari wcwidth", Ansi::Method::WcWidth, "नमस्ते", 4},
    {"devanagari grapheme width", Ansi::Method::GraphemeWidth, "नमस्ते", 3},
    {"zwj family wcwidth", Ansi::Method::WcWidth, "👨‍👩‍👧‍👦", 8},
    {"zwj family grapheme width", Ansi::Method::GraphemeWidth, "👨‍👩‍👧‍👦", 2},
    {"skin tone wcwidth", Ansi::Method::WcWidth, "👍🏽", 4},
    {"skin tone grapheme width", Ansi::Method::GraphemeWidth, "👍🏽", 2},
    {"combining mark wcwidth", Ansi::Method::WcWidth, "é", 1},
    {"combining mark grapheme width", Ansi::Method::GraphemeWidth, "é", 1},
    {"vs16 wcwidth", Ansi::Method::WcWidth, "⚠️", 1},
    {"vs16 grapheme width", Ansi::Method::GraphemeWidth, "⚠️", 2},
  ]

  cases.each do |name, method, input, want|
    it name do
      method.string_width(input).should eq want
    end
  end
end
