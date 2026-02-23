module Ansi
  enum Method : UInt8
    WcWidth
    GraphemeWidth

    def string_width(s : String) : Int32
      Ansi.string_width(self, s)
    end

    def truncate(s : String, length : Int32, tail : String) : String
      Ansi.truncate(self, s, length, tail)
    end

    def truncate_left(s : String, length : Int32, prefix : String) : String
      Ansi.truncate_left(self, s, length, prefix)
    end

    def cut(s : String, left : Int32, right : Int32) : String
      Ansi.cut(self, s, left, right)
    end

    def hardwrap(s : String, length : Int32, preserve_space : Bool) : String
      Ansi.hardwrap(self, s, length, preserve_space)
    end

    def wordwrap(s : String, length : Int32, breakpoints : String) : String
      Ansi.wordwrap(self, s, length, breakpoints)
    end

    def wrap(s : String, length : Int32, breakpoints : String) : String
      Ansi.wrap(self, s, length, breakpoints)
    end

    def decode_sequence(data : Bytes, state : UInt8, p : Parser? = nil) : {Bytes, Int32, Int32, UInt8}
      Ansi.decode_sequence(self, data, state, p)
    end

    def decode_sequence_in_string(data : String, state : UInt8, p : Parser? = nil) : {String, Int32, Int32, UInt8}
      _, width, n, new_state = Ansi.decode_sequence(self, data.to_slice, state, p)
      {data.byte_slice(0, n), width, n, new_state}
    end
  end

  WcWidth       = Method::WcWidth
  GraphemeWidth = Method::GraphemeWidth
end
