require "./color"
require "./image"
require "./iterm2"
require "./kitty"
require "./sixel"

module Ansi
  def self.iterm2(data : String) : String
    "\e]1337;#{data}\a"
  end

  def self.sixel_graphics(p1 : Int32, p2 : Int32, p3 : Int32, payload : Bytes) : String
    String.build do |io|
      io << "\eP"
      io << p1 if p1 >= 0
      io << ';'
      io << p2 if p2 >= 0
      if p3 > 0
        io << ';' << p3
      end
      io << 'q'
      io.write(payload)
      io << "\e\\"
    end
  end

  def self.kitty_graphics(payload : Bytes, opts : Array(String) = [] of String) : String
    String.build do |io|
      io << "\e_G"
      io << opts.join(",")
      if payload.size > 0
        io << ';'
        io.write(payload)
      end
      io << "\e\\"
    end
  end
end
