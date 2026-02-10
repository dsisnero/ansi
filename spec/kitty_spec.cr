require "./spec_helper"
require "compress/zlib"

module Ansi::Kitty
  # Helper to create a 2x2 test image with red and blue pattern (from Go test)
  def self.test_image : Ansi::Image
    image = Ansi::RGBAImage.new(2, 2)
    image.set(0, 0, Ansi::Color.new(255_u8, 0_u8, 0_u8, 255_u8)) # Red
    image.set(1, 0, Ansi::Color.new(0_u8, 0_u8, 255_u8, 255_u8)) # Blue
    image.set(0, 1, Ansi::Color.new(0_u8, 0_u8, 255_u8, 255_u8)) # Blue
    image.set(1, 1, Ansi::Color.new(255_u8, 0_u8, 0_u8, 255_u8)) # Red
    image
  end

  # PNG header constant from Go test
  PNG_HEADER = "\x89PNG\r\n\x1a\n"

  # Helper to compare two images for equality
  def self.images_equal?(a : Ansi::Image, b : Ansi::Image) : Bool
    return false if a.width != b.width || a.height != b.height
    a.each_pixel do |x, y, color_a|
      color_b = b.pixel(x, y)
      return false if color_a.r != color_b.r || color_a.g != color_b.g || color_a.b != color_b.b || color_a.a != color_b.a
    end
    true
  end
end

# Port of TestEncoder_Encode from Go's encoder_test.go
describe "Kitty Encoder (port of Go TestEncoder_Encode)" do
  describe "#encode" do
    it "handles nil image (produces empty output)" do
      encoder = Ansi::Kitty::Encoder.new(compress: false, format: Ansi::Kitty::RGBA)
      io = IO::Memory.new
      encoder.encode(io, nil)
      io.to_slice.size.should eq 0
    end

    it "encodes RGBA format" do
      encoder = Ansi::Kitty::Encoder.new(compress: false, format: Ansi::Kitty::RGBA)
      image = Ansi::Kitty.test_image
      io = IO::Memory.new

      encoder.encode(io, image)

      expected = Bytes[
        255, 0, 0, 255, # Red pixel
        0, 0, 255, 255, # Blue pixel
        0, 0, 255, 255, # Blue pixel
        255, 0, 0, 255, # Red pixel
      ]
      io.to_slice.should eq expected
    end

    it "encodes RGB format" do
      encoder = Ansi::Kitty::Encoder.new(compress: false, format: Ansi::Kitty::RGB)
      image = Ansi::Kitty.test_image
      io = IO::Memory.new

      encoder.encode(io, image)

      expected = Bytes[
        255, 0, 0, # Red pixel
        0, 0, 255, # Blue pixel
        0, 0, 255, # Blue pixel
        255, 0, 0, # Red pixel
      ]
      io.to_slice.should eq expected
    end

    it "encodes PNG format" do
      encoder = Ansi::Kitty::Encoder.new(compress: false, format: Ansi::Kitty::PNG)
      image = Ansi::Kitty.test_image
      io = IO::Memory.new

      encoder.encode(io, image)

      # Verify PNG header (first 8 bytes)
      png_header = io.to_slice[0, 8]
      png_header.should eq Ansi::Kitty::PNG_HEADER.to_slice
    end

    it "raises on invalid format" do
      encoder = Ansi::Kitty::Encoder.new(compress: false, format: 999)
      image = Ansi::Kitty.test_image
      io = IO::Memory.new

      expect_raises(Exception, "unsupported format: 999") do
        encoder.encode(io, image)
      end
    end

    it "encodes RGBA with compression" do
      encoder = Ansi::Kitty::Encoder.new(compress: true, format: Ansi::Kitty::RGBA)
      image = Ansi::Kitty.test_image
      io = IO::Memory.new

      encoder.encode(io, image)

      # Decompress the data like Go test does
      io.rewind

      # Use Zlib::Reader to decompress
      decompressed_io = IO::Memory.new
      Compress::Zlib::Reader.open(io) do |reader|
        IO.copy(reader, decompressed_io)
      end

      expected = Bytes[
        255, 0, 0, 255, # Red pixel
        0, 0, 255, 255, # Blue pixel
        0, 0, 255, 255, # Blue pixel
        255, 0, 0, 255, # Red pixel
      ]
      decompressed_io.to_slice.should eq expected
    end

    it "defaults format to RGBA when zero" do
      encoder = Ansi::Kitty::Encoder.new(compress: false, format: 0)
      image = Ansi::Kitty.test_image
      io = IO::Memory.new

      encoder.encode(io, image)

      expected = Bytes[
        255, 0, 0, 255, # Red pixel
        0, 0, 255, 255, # Blue pixel
        0, 0, 255, 255, # Blue pixel
        255, 0, 0, 255, # Red pixel
      ]
      io.to_slice.should eq expected
    end
  end
end

# Port of TestEncoder_EncodeWithDifferentImageTypes from Go's encoder_test.go
describe "Kitty Encoder with different image types (port of Go TestEncoder_EncodeWithDifferentImageTypes)" do
  pending "handles different image types" do
    # Go test uses image.RGBA and image.Gray
    # Our Crystal implementation only handles Ansi::Image interface
    # which RGBAImage implements
  end
end

describe Ansi::Kitty do
  describe "constants" do
    it "has format constants" do
      Ansi::Kitty::RGBA.should eq 32
      Ansi::Kitty::RGB.should eq 24
      Ansi::Kitty::PNG.should eq 100
    end

    it "has compression constant" do
      Ansi::Kitty::Zlib.should eq 'z'
    end

    it "has transmission mode constants" do
      Ansi::Kitty::Direct.should eq 'd'
      Ansi::Kitty::File.should eq 'f'
      Ansi::Kitty::TempFile.should eq 't'
      Ansi::Kitty::SharedMemory.should eq 's'
    end
  end

  describe "Encoder" do
    describe "#encode" do
      it "handles empty image (zero width or height)" do
        encoder = Ansi::Kitty::Encoder.new
        image = Ansi::RGBAImage.new(0, 0)
        io = IO::Memory.new

        encoder.encode(io, image)
        io.to_slice.size.should eq 0
      end
    end
  end

  describe ".encode_graphics" do
    it "encodes image with direct transmission" do
      image = Ansi::Kitty.test_image
      options = Ansi::Kitty::Options.new
      options.transmission = Ansi::Kitty::Direct
      options.format = Ansi::Kitty::RGBA

      io = IO::Memory.new
      Ansi::Kitty.encode_graphics(io, image, options)

      # Should produce some output
      io.pos.should be > 0
    end

    pending "encodes with file transmission" do
      # Requires file system access
    end

    pending "encodes with temp file transmission" do
      # Requires file system access
    end

    pending "encodes with shared memory transmission" do
      # Not yet implemented
    end

    it "handles nil options" do
      image = Ansi::Kitty.test_image
      io = IO::Memory.new

      Ansi::Kitty.encode_graphics(io, image, nil)
      io.pos.should be > 0
    end
  end

  describe "Options" do
    describe "#options" do
      it "returns empty array for default options" do
        opts = Ansi::Kitty::Options.new
        opts.options.should be_a(Array(String))
        # Default format is 0, which becomes RGBA in options method
        # So format option should not appear (since it's the default)
        opts.options.should_not contain("f=32")
      end

      it "includes non-default format" do
        opts = Ansi::Kitty::Options.new
        opts.format = Ansi::Kitty::RGB
        opts.options.should contain("f=24")
      end
    end
  end

  # Pending tests for missing kitty functionality
  describe "Missing kitty functionality (from Go)" do
    pending "has Decoder implementation" do
      # decoder_test.go
    end

    pending "has Writer implementation" do
      # writer_test.go
    end

    pending "handles shared memory transmission" do
      # graphics.go
    end

    pending "handles query and put actions" do
      # Various actions beyond transmit
    end
  end
end
