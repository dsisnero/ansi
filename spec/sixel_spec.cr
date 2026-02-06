require "./spec_helper"

describe Ansi::Sixel do
  describe "Raster" do
    it "basic case" do
      raster = Ansi::Sixel::Raster.new(pan: 1, pad: 2)
      raster.to_s.should eq "\"1;2"
    end

    it "with ph and pv" do
      raster = Ansi::Sixel::Raster.new(pan: 2, pad: 3, ph: 4, pv: 5)
      raster.to_s.should eq "\"2;3;4;5"
    end

    it "zero pad converts to 1,1" do
      raster = Ansi::Sixel::Raster.new(pan: 2, pad: 0)
      raster.to_s.should eq "\"1;1"
    end

    it "with ph only" do
      raster = Ansi::Sixel::Raster.new(pan: 1, pad: 2, ph: 3, pv: 0)
      raster.to_s.should eq "\"1;2;3;0"
    end

    it "with pv only" do
      raster = Ansi::Sixel::Raster.new(pan: 1, pad: 2, ph: 0, pv: 3)
      raster.to_s.should eq "\"1;2;0;3"
    end
  end

  describe "Repeat" do
    it "basic repeat" do
      repeat = Ansi::Sixel::Repeat.new(count: 3, char: 'A')
      repeat.to_s.should eq "!3A"
    end

    it "single digit" do
      repeat = Ansi::Sixel::Repeat.new(count: 5, char: '#')
      repeat.to_s.should eq "!5#"
    end

    it "multiple digits" do
      repeat = Ansi::Sixel::Repeat.new(count: 123, char: 'x')
      repeat.to_s.should eq "!123x"
    end

    it "zero count" do
      repeat = Ansi::Sixel::Repeat.new(count: 0, char: 'B')
      repeat.to_s.should eq "!0B"
    end
  end

  # Missing functionality tests - marked as pending
  describe "WriteColor (from Go TestWriteColor)" do
    it "simple color number" do
      io = IO::Memory.new
      Ansi::Sixel.write_color(io, 1, 0, 0, 0, 0)
      io.to_s.should eq "#1"
    end

    it "RGB color" do
      io = IO::Memory.new
      Ansi::Sixel.write_color(io, 1, 2, 50, 60, 70)
      io.to_s.should eq "#1;2;50;60;70"
    end

    it "HLS color" do
      io = IO::Memory.new
      Ansi::Sixel.write_color(io, 2, 1, 180, 50, 100)
      io.to_s.should eq "#2;1;180;50;100"
    end

    it "invalid pu > 2" do
      io = IO::Memory.new
      Ansi::Sixel.write_color(io, 1, 3, 0, 0, 0)
      io.to_s.should eq "#1"
    end
  end

  describe "DecodeColor (from Go TestDecodeColor)" do
    it "simple color number" do
      data = "#1".to_slice
      color, n = Ansi::Sixel.decode_color(data)
      color.pc.should eq 1
      color.pu.should eq 0
      color.px.should eq 0
      color.py.should eq 0
      color.pz.should eq 0
      n.should eq 2
    end

    it "RGB color" do
      data = "#1;2;50;60;70".to_slice
      color, n = Ansi::Sixel.decode_color(data)
      color.pc.should eq 1
      color.pu.should eq 2
      color.px.should eq 50
      color.py.should eq 60
      color.pz.should eq 70
      n.should eq 13
    end

    it "HLS color" do
      data = "#2;1;180;50;100".to_slice
      color, n = Ansi::Sixel.decode_color(data)
      color.pc.should eq 2
      color.pu.should eq 1
      color.px.should eq 180
      color.py.should eq 50
      color.pz.should eq 100
      n.should eq 15
    end

    it "empty input" do
      data = "".to_slice
      color, n = Ansi::Sixel.decode_color(data)
      color.pc.should eq 0
      color.pu.should eq 0
      color.px.should eq 0
      color.py.should eq 0
      color.pz.should eq 0
      n.should eq 0
    end

    it "invalid introducer" do
      data = "X1".to_slice
      color, n = Ansi::Sixel.decode_color(data)
      color.pc.should eq 0
      color.pu.should eq 0
      color.px.should eq 0
      color.py.should eq 0
      color.pz.should eq 0
      n.should eq 0
    end

    it "incomplete sequence" do
      data = "#".to_slice
      color, n = Ansi::Sixel.decode_color(data)
      color.pc.should eq 0
      color.pu.should eq 0
      color.px.should eq 0
      color.py.should eq 0
      color.pz.should eq 0
      n.should eq 0
    end
  end

  describe "Color RGBA (from Go TestColor_RGBA)" do
    it "default color map 0 (black)" do
      color = Ansi::Sixel::Color.new(pc: 0)
      r, g, b, a = color.rgba
      r.should eq 0x0000_u32
      g.should eq 0x0000_u32
      b.should eq 0x0000_u32
      a.should eq 0xFFFF_u32
    end

    it "RGB mode (50%, 60%, 70%)" do
      color = Ansi::Sixel::Color.new(pc: 1, pu: 2, px: 50, py: 60, pz: 70)
      r, g, b, a = color.rgba
      r.should eq 0x8080_u32
      g.should eq 0x9999_u32
      b.should eq 0xB3B3_u32
      a.should eq 0xFFFF_u32
    end

    it "HLS mode (180°, 50%, 100%)" do
      color = Ansi::Sixel::Color.new(pc: 1, pu: 1, px: 180, py: 50, pz: 100)
      r, g, b, a = color.rgba
      r.should eq 0x0000_u32
      g.should eq 0xFFFF_u32
      b.should eq 0xFFFF_u32
      a.should eq 0xFFFF_u32
    end
  end

  describe "sixelRGB (from Go TestSixelRGB)" do
    it "black" do
      color = Ansi::Sixel.sixel_rgb(0, 0, 0)
      color.r.should eq 0_u8
      color.g.should eq 0_u8
      color.b.should eq 0_u8
      color.a.should eq 0xFF_u8
    end

    it "white" do
      color = Ansi::Sixel.sixel_rgb(100, 100, 100)
      color.r.should eq 0xFF_u8
      color.g.should eq 0xFF_u8
      color.b.should eq 0xFF_u8
      color.a.should eq 0xFF_u8
    end

    it "red" do
      color = Ansi::Sixel.sixel_rgb(100, 0, 0)
      color.r.should eq 0xFF_u8
      color.g.should eq 0_u8
      color.b.should eq 0_u8
      color.a.should eq 0xFF_u8
    end

    it "half intensity" do
      color = Ansi::Sixel.sixel_rgb(50, 50, 50)
      color.r.should eq 128_u8
      color.g.should eq 128_u8
      color.b.should eq 128_u8
      color.a.should eq 0xFF_u8
    end
  end

  describe "sixelHLS (from Go TestSixelHLS)" do
    it "black" do
      color = Ansi::Sixel.sixel_hls(0, 0, 0)
      color.r.should eq 0_u8
      color.g.should eq 0_u8
      color.b.should eq 0_u8
      color.a.should eq 0xFF_u8
    end

    it "white" do
      color = Ansi::Sixel.sixel_hls(0, 100, 0)
      color.r.should eq 0xFF_u8
      color.g.should eq 0xFF_u8
      color.b.should eq 0xFF_u8
      color.a.should eq 0xFF_u8
    end

    it "pure red" do
      color = Ansi::Sixel.sixel_hls(0, 50, 100)
      color.r.should eq 0xFF_u8
      color.g.should eq 0_u8
      color.b.should eq 0_u8
      color.a.should eq 0xFF_u8
    end

    it "pure green" do
      color = Ansi::Sixel.sixel_hls(120, 50, 100)
      color.r.should eq 0_u8
      color.g.should eq 0xFF_u8
      color.b.should eq 0_u8
      color.a.should eq 0xFF_u8
    end

    it "pure blue" do
      color = Ansi::Sixel.sixel_hls(240, 50, 100)
      color.r.should eq 0_u8
      color.g.should eq 0_u8
      color.b.should eq 0xFF_u8
      color.a.should eq 0xFF_u8
    end
  end

  describe "DecodeRaster (from Go TestDecodeRaster)" do
    it "basic case" do
      data = "\"1;2".to_slice
      raster, n = Ansi::Sixel.decode_raster(data)
      raster.pan.should eq 1
      raster.pad.should eq 2
      raster.ph.should eq 0
      raster.pv.should eq 0
      n.should eq 4
    end

    it "full attributes" do
      data = "\"2;3;4;5".to_slice
      raster, n = Ansi::Sixel.decode_raster(data)
      raster.pan.should eq 2
      raster.pad.should eq 3
      raster.ph.should eq 4
      raster.pv.should eq 5
      n.should eq 8
    end

    it "empty input" do
      data = "".to_slice
      raster, n = Ansi::Sixel.decode_raster(data)
      raster.pan.should eq 0
      raster.pad.should eq 0
      raster.ph.should eq 0
      raster.pv.should eq 0
      n.should eq 0
    end

    it "invalid start character" do
      data = "x1;2".to_slice
      raster, n = Ansi::Sixel.decode_raster(data)
      raster.pan.should eq 0
      raster.pad.should eq 0
      raster.ph.should eq 0
      raster.pv.should eq 0
      n.should eq 0
    end

    it "too short" do
      data = "\"1".to_slice
      raster, n = Ansi::Sixel.decode_raster(data)
      raster.pan.should eq 1
      raster.pad.should eq 0
      raster.ph.should eq 0
      raster.pv.should eq 0
      n.should eq 2
    end

    it "invalid character" do
      data = "\"1;a".to_slice
      raster, n = Ansi::Sixel.decode_raster(data)
      raster.pan.should eq 1
      raster.pad.should eq 0
      raster.ph.should eq 0
      raster.pv.should eq 0
      n.should eq 3
    end

    it "partial attributes" do
      data = "\"1;2;3".to_slice
      raster, n = Ansi::Sixel.decode_raster(data)
      raster.pan.should eq 1
      raster.pad.should eq 2
      raster.ph.should eq 3
      raster.pv.should eq 0
      n.should eq 6
    end
  end

  describe "DecodeRepeat (from Go TestDecodeRepeat)" do
    it "basic repeat" do
      data = "!3A".to_slice
      repeat, n = Ansi::Sixel.decode_repeat(data)
      repeat.count.should eq 3
      repeat.char.should eq 'A'
      n.should eq 3
    end

    it "multiple digits" do
      data = "!123x".to_slice
      repeat, n = Ansi::Sixel.decode_repeat(data)
      repeat.count.should eq 123
      repeat.char.should eq 'x'
      n.should eq 5
    end

    it "empty input" do
      data = "".to_slice
      repeat, n = Ansi::Sixel.decode_repeat(data)
      repeat.count.should eq 0
      repeat.char.should eq '\0'
      n.should eq 0
    end

    it "invalid introducer" do
      data = "X3A".to_slice
      repeat, n = Ansi::Sixel.decode_repeat(data)
      repeat.count.should eq 0
      repeat.char.should eq '\0'
      n.should eq 0
    end

    it "incomplete sequence" do
      data = "!3".to_slice
      repeat, n = Ansi::Sixel.decode_repeat(data)
      repeat.count.should eq 0
      repeat.char.should eq '\0'
      n.should eq 0
    end
  end

  describe "Palette creation (from Go TestPaletteCreationRedGreen)" do
    pending "way too many colors" do
      # maxColors: 16, expected palette of 4 colors
    end

    pending "just the right number of colors" do
      # maxColors: 4, expected palette of 4 colors
    end

    pending "color reduction" do
      # maxColors: 2, expected palette of 2 colors (averaged)
    end
  end

  describe "Palette with semi-transparency (from Go TestPaletteWithSemiTransparency)" do
    pending "just the right number of colors" do
      # maxColors: 4, expected palette of 4 colors
    end

    pending "color reduction" do
      # maxColors: 2, expected palette of 2 colors
    end
  end

  describe "ScanSize (from Go TestScanSize)" do
    it "two lines" do
      decoder = Ansi::Sixel::Decoder.new
      width, height = decoder.scan_size("~~~~~~-~~~~~~-".to_slice)
      width.should eq 6
      height.should eq 12
    end

    it "two lines no newline at end" do
      decoder = Ansi::Sixel::Decoder.new
      width, height = decoder.scan_size("~~~~~~-~~~~~~".to_slice)
      width.should eq 6
      height.should eq 12
    end

    it "no pixels" do
      decoder = Ansi::Sixel::Decoder.new
      width, height = decoder.scan_size("".to_slice)
      width.should eq 0
      height.should eq 0
    end

    it "smaller carriage returns" do
      decoder = Ansi::Sixel::Decoder.new
      width, height = decoder.scan_size("~$~~$~~~$~~~~$~~~~~$~~~~~~".to_slice)
      width.should eq 6
      height.should eq 6
    end

    it "transparent" do
      decoder = Ansi::Sixel::Decoder.new
      width, height = decoder.scan_size("??????".to_slice)
      width.should eq 6
      height.should eq 6
    end

    it "RLE" do
      decoder = Ansi::Sixel::Decoder.new
      width, height = decoder.scan_size("??!20?".to_slice)
      width.should eq 22
      height.should eq 6
    end

    it "Colors" do
      decoder = Ansi::Sixel::Decoder.new
      data = "#0;2;0;0;0~~~~~$#1;2;100;100;100;~~~~~~-#0~~~~~~-#1~~~~~~".to_slice
      width, height = decoder.scan_size(data)
      width.should eq 6
      height.should eq 18
    end
  end

  describe "FullImage (from Go TestFullImage)" do
    pending "3x12 single color filled" do
      # imageWidth: 3, imageHeight: 12, bandCount: 2, colors: {0: red}
    end

    pending "3x12 two color filled" do
      # imageWidth: 3, imageHeight: 12, bandCount: 2, colors: alternating blue/green
    end

    pending "3x12 8 color with right gutter" do
      # imageWidth: 3, imageHeight: 12, bandCount: 2, colors: complex map
    end

    pending "3x12 single color with transparent band in the middle" do
      # imageWidth: 3, imageHeight: 12, bandCount: 2, colors: red with transparent band
    end

    pending "3x5 single color" do
      # imageWidth: 3, imageHeight: 5, bandCount: 1, colors: red
    end

    pending "12x4 single color use RLE" do
      # imageWidth: 12, imageHeight: 4, bandCount: 1, colors: red
    end

    pending "12x1 two color use RLE" do
      # imageWidth: 12, imageHeight: 1, bandCount: 1, colors: red and green
    end

    pending "12x12 single color use RLE" do
      # imageWidth: 12, imageHeight: 12, bandCount: 2, colors: red
    end
  end

  describe "Encoder" do
    it "exists" do
      Ansi::Sixel::Encoder.new.should be_a(Ansi::Sixel::Encoder)
    end

    # Actual encoder tests will need image creation and encoding
    # We'll add those after we verify the encoder works
  end
end
