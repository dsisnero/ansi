require "./displaywidth_trie"

module Ansi
  # Port of the display-width lookup used by github.com/clipperhouse/displaywidth
  # v0.11.0. The generated property tables live in `displaywidth_trie.cr`.
  module DisplayWidth
    ZERO_WIDTH           = 1_u8
    WIDE                 = 2_u8
    EAST_ASIAN_AMBIGUOUS = 3_u8
    UPPER_BOUND          = 3_u8

    def self.grapheme_width(cluster : String, east_asian : Bool = false) : Int32
      grapheme_width(cluster.to_slice, east_asian)
    end

    def self.grapheme_width(cluster : Bytes, east_asian : Bool = false) : Int32
      return 0 if cluster.empty?
      return ascii_width(cluster[0]) if cluster.size == 1
      return 0 if cluster[0] <= 0x1f

      property, size = lookup(cluster)
      if property != WIDE && size > 0 && cluster.size >= size + 3
        if cluster[size] == 0xef && cluster[size + 1] == 0xb8 && cluster[size + 2] == 0x8f
          property = WIDE
        end
      end
      property = WIDE if east_asian && property == EAST_ASIAN_AMBIGUOUS

      property_width(property)
    end

    private def self.ascii_width(byte : UInt8) : Int32
      byte <= 0x1f || byte == 0x7f ? 0 : 1
    end

    private def self.property_width(property : UInt8) : Int32
      case property
      when ZERO_WIDTH
        0
      when WIDE
        2
      else
        1
      end
    end

    private def self.lookup(data : Bytes) : {UInt8, Int32}
      c0 = data[0]
      return {VALUES[c0], 1} if c0 < 0x80
      return {0_u8, 1} if c0 < 0xc2
      return lookup2(data) if c0 < 0xe0
      return lookup3(data) if c0 < 0xf0
      return lookup4(data) if c0 < 0xf8

      {0_u8, 1}
    end

    private def self.lookup2(data : Bytes) : {UInt8, Int32}
      return {0_u8, 0} if data.size < 2

      i = INDEX[data[0]].to_i32
      c1 = data[1]
      return {0_u8, 1} if c1 < 0x80 || c1 >= 0xc0

      {lookup_value(i, c1), 2}
    end

    private def self.lookup3(data : Bytes) : {UInt8, Int32}
      return {0_u8, 0} if data.size < 3

      i = INDEX[data[0]].to_i32
      c1 = data[1]
      return {0_u8, 1} if c1 < 0x80 || c1 >= 0xc0

      i = INDEX[(i << 6) + c1].to_i32
      c2 = data[2]
      return {0_u8, 2} if c2 < 0x80 || c2 >= 0xc0

      {lookup_value(i, c2), 3}
    end

    private def self.lookup4(data : Bytes) : {UInt8, Int32}
      return {0_u8, 0} if data.size < 4

      i = INDEX[data[0]].to_i32
      c1 = data[1]
      return {0_u8, 1} if c1 < 0x80 || c1 >= 0xc0

      i = INDEX[(i << 6) + c1].to_i32
      c2 = data[2]
      return {0_u8, 2} if c2 < 0x80 || c2 >= 0xc0

      i = INDEX[(i << 6) + c2].to_i32
      c3 = data[3]
      return {0_u8, 3} if c3 < 0x80 || c3 >= 0xc0

      {lookup_value(i, c3), 4}
    end

    private def self.lookup_value(block : Int32, byte : UInt8) : UInt8
      VALUES[(block << 6) + byte]
    end
  end
end
