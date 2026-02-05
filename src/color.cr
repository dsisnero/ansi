module Ansi
  struct Color
    getter r : UInt8
    getter g : UInt8
    getter b : UInt8
    getter a : UInt8

    def initialize(@r : UInt8, @g : UInt8, @b : UInt8, @a : UInt8 = 0xff_u8)
    end

    def self.black : Color
      Color.new(0_u8, 0_u8, 0_u8, 0xff_u8)
    end
  end
end
