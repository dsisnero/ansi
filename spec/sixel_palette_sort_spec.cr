require "./spec_helper"

describe "Ansi::Sixel::PaletteSort" do
  describe "xorshift" do
    it "produces the same sequence as Go" do
      random = Ansi::Sixel::PaletteSort::Xorshift.new(1_u64)
      expected = [
        1082269761_u64,
        1152992998833853505_u64,
        11177516664432764457_u64,
        17678023832001937445_u64,
        9659130143999365733_u64,
        17775799001133815809_u64,
        11693034620340510321_u64,
        14279964170112293133_u64,
        9024654201992055039_u64,
        8332670729032836398_u64,
      ]
      expected.each do |value|
        random.next_value.should eq value
      end
    end
  end

  describe ".next_power_of_two" do
    it "rounds up like Go's bits.Len-based helper" do
      {
          0 => 1_u32,
          1 => 2_u32,
          2 => 4_u32,
          3 => 4_u32,
          7 => 8_u32,
          8 => 16_u32,
          9 => 16_u32,
         16 => 32_u32,
         17 => 32_u32,
        100 => 128_u32,
      }.each do |length, want|
        Ansi::Sixel::PaletteSort.next_power_of_two(length).should eq want
      end
    end
  end

  describe ".sort!" do
    it "sorts small arrays with insertion sort" do
      values = [5, 1, 4, 1, 5, 9, 2, 6]
      Ansi::Sixel::PaletteSort.sort!(values) { |left, right| left <=> right }
      values.should eq [1, 1, 2, 4, 5, 5, 6, 9]
    end

    it "sorts large arrays with pdqsort" do
      values = (0...100).map { |index| (index * 37) % 101 }
      expected = values.sort
      Ansi::Sixel::PaletteSort.sort!(values) { |left, right| left <=> right }
      values.should eq expected
    end

    it "sorts descending input" do
      values = (0...80).to_a.reverse
      Ansi::Sixel::PaletteSort.sort!(values) { |left, right| left <=> right }
      values.should eq (0...80).to_a
    end

    it "sorts arrays with duplicate keys" do
      values = [3, 1, 2, 3, 1, 2, 3, 1, 2, 3]
      Ansi::Sixel::PaletteSort.sort!(values) { |left, right| left <=> right }
      values.should eq [1, 1, 1, 2, 2, 2, 3, 3, 3, 3]
    end
  end
end
