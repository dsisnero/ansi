require "./spec_helper"

# Invalid UTF-8 is not a valid input for a terminal, but Go's `x/ansi` still
# defines what happens to the bytes: they occupy no cells, they are dropped by
# `Strip`, and they are copied through verbatim by `Cut`/`Truncate` (which fall
# through to "write the byte"). These expectations come from the vendored Go
# module in `vendor/x/ansi`, so the port keeps the same byte-level behaviour
# instead of raising or silently trimming.
private def raw_string(bytes : Bytes) : String
  String.build(&.write(bytes))
end

describe "Ansi byte-level handling of invalid UTF-8" do
  it "measures invalid bytes as zero width and keeps them in cut/truncate" do
    [Bytes[0xff_u8], Bytes[0xfe_u8], Bytes[0xc0_u8]].each do |bytes|
      s = raw_string(bytes)

      Ansi.string_width(s).should eq(0)
      Ansi.string_width_wc(s).should eq(0)
      Ansi.strip(s).should eq("")
      Ansi.cut(s, 0, 10).bytes.should eq(bytes.to_a)
      Ansi.truncate(s, 5, "…").bytes.should eq(bytes.to_a)
    end
  end

  it "drops invalid bytes from strip but keeps them between text" do
    s = raw_string(Bytes[0x61_u8, 0xff_u8, 0x62_u8])

    Ansi.string_width(s).should eq(2)
    Ansi.strip(s).should eq("ab")
    Ansi.cut(s, 0, 10).bytes.should eq([0x61_u8, 0xff_u8, 0x62_u8])
    Ansi.truncate(s, 5, "…").bytes.should eq([0x61_u8, 0xff_u8, 0x62_u8])
  end

  # A lead byte whose continuations are cut off is still one cell in Go, and its
  # raw bytes survive Strip: `utf8.DecodeRune` reports RuneError with size 1 and
  # the parser has already collected the byte.
  it "treats a truncated sequence as one width-1 cluster" do
    s = raw_string(Bytes[0xe3_u8, 0x81_u8])

    Ansi.string_width(s).should eq(1)
    Ansi.string_width_wc(s).should eq(1)
    Ansi.strip(s).bytes.should eq([0xe3_u8, 0x81_u8])
    Ansi.cut(s, 0, 10).bytes.should eq([0xe3_u8, 0x81_u8])
  end
end
