require "./spec_helper"

describe Ansi do
  passthrough_cases = [
    {
      name:   "empty",
      seq:    "",
      limit:  0,
      screen: "\eP\e\\",
      tmux:   "\ePtmux;\e\\",
    },
    {
      name:   "short",
      seq:    "hello",
      limit:  0,
      screen: "\ePhello\e\\",
      tmux:   "\ePtmux;hello\e\\",
    },
    {
      name:   "limit",
      seq:    "foobarbaz",
      limit:  3,
      screen: "\ePfoo\e\\\ePbar\e\\\ePbaz\e\\",
      tmux:   "\ePtmux;foobarbaz\e\\",
    },
    {
      name:   "escaped",
      seq:    "\e]52;c;Zm9vYmFy\a",
      limit:  0,
      screen: "\eP\e]52;c;Zm9vYmFy\a\e\\",
      tmux:   "\ePtmux;\e\e]52;c;Zm9vYmFy\a\e\\",
    },
  ]

  describe ".screen_passthrough" do
    passthrough_cases.each_with_index do |tt, i|
      it tt[:name] do
        Ansi.screen_passthrough(tt[:seq], tt[:limit]).should eq(tt[:screen]), "case: #{i + 1}"
      end
    end
  end

  describe ".tmux_passthrough" do
    passthrough_cases.each_with_index do |tt, i|
      it tt[:name] do
        Ansi.tmux_passthrough(tt[:seq]).should eq(tt[:tmux]), "case: #{i + 1}"
      end
    end
  end
end
