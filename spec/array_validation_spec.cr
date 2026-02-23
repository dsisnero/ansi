require "./spec_helper"

# Path to Go source file
GO_COLOR_FILE = "../x/ansi/color.go"

module ArrayValidation
  # Helper to parse Go's color.RGBA array
  def self.parse_go_ansi_hex(file_path : String) : Array(Tuple(UInt8, UInt8, UInt8, UInt8))?
    return unless File.exists?(file_path)
    content = File.read(file_path)
    lines = content.lines
    start_idx = lines.index(&.includes?("var ansiHex = [...]color.RGBA{"))
    return unless start_idx
    start_idx += 1
    entries = [] of Tuple(UInt8, UInt8, UInt8, UInt8)
    i = start_idx
    while i < lines.size
      line = lines[i].strip
      break if line == "}" # end of array
      # Match pattern: {R: 0x00, G: 0x00, B: 0x00, A: 0xff},
      if line =~ /\{R:\s*(0x[0-9a-fA-F]+),\s*G:\s*(0x[0-9a-fA-F]+),\s*B:\s*(0x[0-9a-fA-F]+),\s*A:\s*(0x[0-9a-fA-F]+)\}/
        r = $1.to_u8(16)
        g = $2.to_u8(16)
        b = $3.to_u8(16)
        a = $4.to_u8(16)
        entries << {r, g, b, a}
      end
      i += 1
    end
    entries
  end

  # Helper to parse Go's BasicColor array (ansi256To16)
  def self.parse_go_ansi256_to_16(file_path : String) : Array(UInt8)?
    return unless File.exists?(file_path)
    content = File.read(file_path)
    lines = content.lines
    start_idx = lines.index(&.includes?("var ansi256To16 = [...]BasicColor{"))
    return unless start_idx
    start_idx += 1
    entries = [] of UInt8
    i = start_idx
    while i < lines.size
      line = lines[i].strip
      break if line == "}" # end of array
      # Match pattern: index: value,   or continuation lines with just value,
      if line =~ /^\d+:\s*(\d+),/
        entries << $1.to_u8
      elsif line =~ /^\s*(\d+),/
        entries << $1.to_u8
      end
      i += 1
    end
    entries
  end

  # Expose private constants from Ansi module
  module ::Ansi
    def self.ansi_hex : Array(Color)
      ANSI_HEX
    end

    def self.ansi256_to_16 : StaticArray(UInt8, 256)
      ANSI256_TO_16
    end
  end
end

# This spec validates that Crystal's constant arrays match the Go source.
# It reads the Go source file from the vendor submodule and compares values.
describe "Constant array validation" do
  describe "ANSI_HEX" do
    it "matches Go's ansiHex array" do
      go_entries = ArrayValidation.parse_go_ansi_hex(GO_COLOR_FILE)
      unless go_entries
        puts "Skipping ANSI_HEX validation: Go source file not found or could not be parsed"
        next
      end

      crystal_array = Ansi.ansi_hex
      crystal_array.size.should eq(256)
      go_entries.not_nil!.size.should eq(256)

      mismatches = [] of Int32
      (0...256).each do |i|
        c = crystal_array[i]
        g = go_entries.not_nil![i]
        if c.r != g[0] || c.g != g[1] || c.b != g[2] || c.a != g[3]
          mismatches << i
        end
      end

      if !mismatches.empty?
        fail "ANSI_HEX mismatches at indices: #{mismatches.first(10).join(", ")}" +
             " (total #{mismatches.size})"
      end
    end
  end

  describe "ANSI256_TO_16" do
    it "matches Go's ansi256To16 array" do
      go_entries = ArrayValidation.parse_go_ansi256_to_16(GO_COLOR_FILE)
      unless go_entries
        puts "Skipping ANSI256_TO_16 validation: Go source file not found or could not be parsed"
        next
      end

      crystal_array = Ansi.ansi256_to_16
      crystal_array.size.should eq(256)
      go_entries.not_nil!.size.should eq(256)

      mismatches = [] of Int32
      (0...256).each do |i|
        if crystal_array[i] != go_entries.not_nil![i]
          mismatches << i
        end
      end

      if !mismatches.empty?
        fail "ANSI256_TO_16 mismatches at indices: #{mismatches.first(10).join(", ")}" +
             " (total #{mismatches.size})"
      end
    end
  end
end
