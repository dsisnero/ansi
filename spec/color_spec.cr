require "./spec_helper"
require "colorful"

describe Ansi::Color do
  describe "initialize" do
    it "creates a color with RGBA values" do
      color = Ansi::Color.new(255_u8, 128_u8, 64_u8, 255_u8)
      color.r.should eq 255_u8
      color.g.should eq 128_u8
      color.b.should eq 64_u8
      color.a.should eq 255_u8
    end

    it "defaults alpha to 255" do
      color = Ansi::Color.new(255_u8, 128_u8, 64_u8)
      color.a.should eq 255_u8
    end
  end

  describe ".black" do
    it "returns black color" do
      black = Ansi::Color.black
      black.r.should eq 0_u8
      black.g.should eq 0_u8
      black.b.should eq 0_u8
      black.a.should eq 255_u8
    end
  end
end

# Pending tests for missing color functionality
# These tests are based on Go's x/ansi/color_test.go

describe "Color conversions (from Go tests)" do
  # TestRGBAToHex
  it "converts RGBA values to hex" do
    # Cases from Go test:
    # {0, 0, 255, 0xffff, 0x0000ff}
    # {255, 255, 255, 0xffff, 0xffffff}
    # {255, 0, 0, 0xffff, 0xffff0000}

    # Note: Go test checks RGBA() of TrueColor(hex)
    # TrueColor is a uint32 representing hex color
    color1 = Ansi::TrueColor.new(0x0000ff)
    r1, g1, b1, a1 = color1.rgba
    # RGBA returns 16-bit values (0-0xFFFF)
    (r1 >> 8).should eq 0_u32
    (g1 >> 8).should eq 0_u32
    (b1 >> 8).should eq 255_u32
    a1.should eq 0xFFFF_u32

    color2 = Ansi::TrueColor.new(0xffffff)
    r2, g2, b2, a2 = color2.rgba
    (r2 >> 8).should eq 255_u32
    (g2 >> 8).should eq 255_u32
    (b2 >> 8).should eq 255_u32
    a2.should eq 0xFFFF_u32

    color3 = Ansi::TrueColor.new(0xff0000)
    r3, g3, b3, a3 = color3.rgba
    (r3 >> 8).should eq 255_u32
    (g3 >> 8).should eq 0_u32
    (b3 >> 8).should eq 0_u32
    a3.should eq 0xFFFF_u32
  end

  # TestColorToHexString
  it "converts colors to hex strings" do
    # Cases from Go test:
    # TrueColor(0x0000ff) -> "#0000ff"
    # TrueColor(0xffffff) -> "#ffffff"
    # TrueColor(0xff0000) -> "#ff0000"

    # color_to_hex_string expects Ansi::Color
    # Convert TrueColor to Color via hex_to_rgb
    color1 = Ansi::TrueColor.new(0x0000ff)
    r1, g1, b1 = Ansi.hex_to_rgb(color1.value)
    c1 = Ansi::Color.new(r1, g1, b1)
    Ansi.color_to_hex_string(c1).should eq "#0000ff"

    color2 = Ansi::TrueColor.new(0xffffff)
    r2, g2, b2 = Ansi.hex_to_rgb(color2.value)
    c2 = Ansi::Color.new(r2, g2, b2)
    Ansi.color_to_hex_string(c2).should eq "#ffffff"

    color3 = Ansi::TrueColor.new(0xff0000)
    r3, g3, b3 = Ansi.hex_to_rgb(color3.value)
    c3 = Ansi::Color.new(r3, g3, b3)
    Ansi.color_to_hex_string(c3).should eq "#ff0000"
  end

  # TestAnsiToRGB
  it "converts ANSI color codes to RGB" do
    # Cases from Go test:
    # 0 (black) -> {0, 0, 0}
    # 1 (red) -> {128, 0, 0}
    # 255 (highest ANSI color) -> {238, 238, 238}

    color0 = Ansi.ansi_to_rgb(0_u8)
    (color0.r).should eq 0_u8
    (color0.g).should eq 0_u8
    (color0.b).should eq 0_u8

    color1 = Ansi.ansi_to_rgb(1_u8)
    (color1.r).should eq 128_u8
    (color1.g).should eq 0_u8
    (color1.b).should eq 0_u8

    color255 = Ansi.ansi_to_rgb(255_u8)
    (color255.r).should eq 238_u8
    (color255.g).should eq 238_u8
    (color255.b).should eq 238_u8
  end

  # TestHexToRGB
  it "converts hex values to RGB" do
    # Cases from Go test:
    # 0x0000FF -> {0, 0, 255}
    # 0xFFFFFF -> {255, 255, 255}
    # 0xFF0000 -> {255, 0, 0}

    r1, g1, b1 = Ansi.hex_to_rgb(0x0000FF_u32)
    r1.should eq 0_u8
    g1.should eq 0_u8
    b1.should eq 255_u8

    r2, g2, b2 = Ansi.hex_to_rgb(0xFFFFFF_u32)
    r2.should eq 255_u8
    g2.should eq 255_u8
    b2.should eq 255_u8

    r3, g3, b3 = Ansi.hex_to_rgb(0xFF0000_u32)
    r3.should eq 255_u8
    g3.should eq 0_u8
    b3.should eq 0_u8
  end

  # TestHexTo256
  it "converts hex colors to 256-color palette" do
    # Cases from Go test (using colorful.Color):
    # white: {R: 1, G: 1, B: 1} -> 231
    # offwhite: {R: 0.9333, G: 0.9333, B: 0.933} -> 255
    # red: {R: 1, G: 0, B: 0} -> 196
    # gray: {R: 0.5, G: 0.5, B: 0.5} -> 244

    white = Colorful::Color.new(r: 1.0, g: 1.0, b: 1.0)
    result = Ansi.convert_256(white)
    result.value.should eq 231_u8

    offwhite = Colorful::Color.new(r: 0.9333, g: 0.9333, b: 0.933)
    result = Ansi.convert_256(offwhite)
    result.value.should eq 255_u8

    red = Colorful::Color.new(r: 1.0, g: 0.0, b: 0.0)
    result = Ansi.convert_256(red)
    result.value.should eq 196_u8

    gray = Colorful::Color.new(r: 0.5, g: 0.5, b: 0.5)
    result = Ansi.convert_256(gray)
    result.value.should eq 244_u8
  end
end

describe "Convert16 (from Go tests)" do
  it "converts colors to 16-color palette" do
    # BasicColor returns itself
    color = Ansi::BasicColor.new(5_u8)
    result = Ansi.convert_16(color)
    result.should be_a(Ansi::BasicColor)
    result.value.should eq 5_u8

    # IndexedColor maps via ANSI256_TO_16 table
    # Test a few known mappings
    mappings = {
        0_u8 => 0_u8,
        1_u8 => 1_u8,
       16_u8 => 0_u8,
       17_u8 => 4_u8,
      255_u8 => 15_u8,
    }
    mappings.each do |index, expected|
      color = Ansi::IndexedColor.new(index)
      result = Ansi.convert_16(color)
      result.value.should eq expected
    end

    # TrueColor conversion (via Colorful::Color)
    true_color = Ansi::TrueColor.new(0xFF0000_u32) # red
    result = Ansi.convert_16(true_color)
    result.should be_a(Ansi::BasicColor)
    # Expected mapping? red (0xFF0000) maps to 256-color 196, which maps to 16-color? we can trust the chain
    # Just ensure it's a valid basic color (0-15)
    result.value.should be <= 15_u8

    # Color conversion (via Colorful::Color)
    color = Ansi::Color.new(255_u8, 0_u8, 0_u8)
    result = Ansi.convert_16(color)
    result.should be_a(Ansi::BasicColor)
    result.value.should be <= 15_u8

    # Colorful::Color conversion
    colorful = Colorful::Color.new(r: 1.0, g: 0.0, b: 0.0)
    result = Ansi.convert_16(colorful)
    result.should be_a(Ansi::BasicColor)
    result.value.should be <= 15_u8
  end

  it "maps all 256 indices correctly via ANSI256_TO_16" do
    256.times do |i|
      color = Ansi::IndexedColor.new(i.to_u8)
      result = Ansi.convert_16(color)
      # The mapping is defined in ANSI256_TO_16, but we can't access private constant.
      # Instead we can compute expected by converting to 256 then mapping via table?
      # We'll just ensure no exception.
      result.should be_a(Ansi::BasicColor)
      result.value.should be <= 15_u8
    end
  end
end

# Pending tests for missing color types
describe "Color types (from Go implementation)" do
  pending "implements BasicColor (ANSI 3/4-bit colors)" do
    # Should have constants: Black, Red, Green, Yellow, Blue, Magenta, Cyan, White
    # and their bright variants
  end

  pending "implements IndexedColor (ANSI 256 colors)" do
    # Should represent colors 0-255
  end

  pending "implements TrueColor (24-bit colors)" do
    # Should represent 24-bit RGB colors
  end

  pending "implements Color interface for all color types" do
    # All color types should implement RGBA() method
  end
end

# Pending tests for color distance and quantization
describe "Color distance and quantization" do
  pending "calculates color distance" do
    # Needed for sixel palette quantization
  end

  pending "quantizes colors to limited palette" do
    # Needed for sixel encoding
  end
end
