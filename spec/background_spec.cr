require "./spec_helper"
require "colorful"

describe "Ansi background color functions" do
  describe ".set_foreground_color" do
    it "returns sequence with empty string" do
      Ansi.set_foreground_color("").should eq "\e]10;\a"
    end

    pending "accepts HexColor and returns correct sequence" do
      # Test would use HexColor type
    end
  end

  describe ".set_background_color" do
    it "returns sequence with color string" do
      Ansi.set_background_color("#ff0000").should eq "\e]11;#ff0000\a"
    end
  end

  describe ".set_cursor_color" do
    it "returns sequence with color string" do
      Ansi.set_cursor_color("#00ff00").should eq "\e]12;#00ff00\a"
    end
  end

  describe "constants" do
    it "RequestForegroundColor is correct" do
      Ansi::RequestForegroundColor.should eq "\e]10;?\a"
    end

    it "ResetForegroundColor is correct" do
      Ansi::ResetForegroundColor.should eq "\e]110\a"
    end

    it "RequestBackgroundColor is correct" do
      Ansi::RequestBackgroundColor.should eq "\e]11;?\a"
    end

    it "ResetBackgroundColor is correct" do
      Ansi::ResetBackgroundColor.should eq "\e]111\a"
    end

    it "RequestCursorColor is correct" do
      Ansi::RequestCursorColor.should eq "\e]12;?\a"
    end

    it "ResetCursorColor is correct" do
      Ansi::ResetCursorColor.should eq "\e]112\a"
    end
  end

  # Pending tests for HexColor and other color types
  describe "HexColor type (from Go)" do
    pending "implements HexColor with Hex() method" do
      # Should be similar to Go's ansi.HexColor
    end
  end
end
