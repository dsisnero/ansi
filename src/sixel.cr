require "colorful"

module Ansi
  module Sixel
    LineBreak        = '-'
    CarriageReturn   = '$'
    RepeatIntroducer = '!'
    ColorIntroducer  = '#'
    RasterAttribute  = '"'

    MaxColors = 256

    class ErrInvalidRaster < Exception
    end

    class ErrInvalidColor < Exception
    end

    class ErrInvalidRepeat < Exception
    end

    def self.write_raster(io : IO, pan : Int32, pad : Int32, ph : Int32, pv : Int32) : Int32
      if pad == 0
        return write_raster(io, 1, 1, ph, pv)
      end
      if ph <= 0 && pv <= 0
        io << RasterAttribute << pan << ';' << pad
        return 0
      end
      io << RasterAttribute << pan << ';' << pad << ';' << ph << ';' << pv
      0
    end

    struct Raster
      getter pan : Int32
      getter pad : Int32
      getter ph : Int32
      getter pv : Int32

      def initialize(@pan : Int32, @pad : Int32, @ph : Int32 = 0, @pv : Int32 = 0)
      end

      def to_s : String
        String.build { |io| Sixel.write_raster(io, @pan, @pad, @ph, @pv) }
      end
    end

    def self.write_repeat(io : IO, count : Int32, char : Char) : Int32
      io << RepeatIntroducer << count << char
      0
    end

    struct Repeat
      getter count : Int32
      getter char : Char

      def initialize(@count : Int32, @char : Char)
      end

      def to_s : String
        String.build { |io| Sixel.write_repeat(io, @count, @char) }
      end
    end

    def self.write_color(io : IO, pc : Int32, pu : Int32, px : Int32, py : Int32, pz : Int32) : Int32
      if pu <= 0 || pu > 2
        io << ColorIntroducer << pc
        return 0
      end
      io << ColorIntroducer << pc << ';' << pu << ';' << px << ';' << py << ';' << pz
      0
    end

    def self.decode_color(data : Bytes) : {Color, Int32}
      n = 0
      return {Color.new, n} if data.empty? || data[0] != ColorIntroducer.ord
      if data.size < 2
        return {Color.new, n}
      end

      pc = 0
      pu = 0
      px = 0
      py = 0
      pz = 0

      n = 1
      # Parse pc and possibly pu
      parsing_pc = true
      while n < data.size
        ch = data[n]
        if ch == ';'.ord
          if parsing_pc
            parsing_pc = false
          else
            n += 1
            break
          end
        elsif ch >= '0'.ord && ch <= '9'.ord
          if parsing_pc
            pc = pc * 10 + (ch - '0'.ord).to_i32
          else
            pu = pu * 10 + (ch - '0'.ord).to_i32
          end
        else
          break
        end
        n += 1
      end

      # Parse px, py, pz
      component = 0
      parsing_px = true
      while n < data.size
        ch = data[n]
        if ch == ';'.ord
          if parsing_px
            parsing_px = false
            component = 1
          elsif component == 1
            component = 2
          else
            n += 1
            break
          end
        elsif ch >= '0'.ord && ch <= '9'.ord
          case component
          when 0
            px = px * 10 + (ch - '0'.ord).to_i32
          when 1
            py = py * 10 + (ch - '0'.ord).to_i32
          when 2
            pz = pz * 10 + (ch - '0'.ord).to_i32
          end
        else
          break
        end
        n += 1
      end

      {Color.new(pc, pu, px, py, pz), n}
    end

    def self.decode_raster(data : Bytes) : {Raster, Int32}
      n = 0
      return {Raster.new(0, 0, 0, 0), n} if data.empty? || data[0] != RasterAttribute.ord

      pan = 0
      pad = 0
      ph = 0
      pv = 0

      n = 1
      component = 0
      while n < data.size
        ch = data[n]
        if ch == ';'.ord
          component += 1
        elsif ch >= '0'.ord && ch <= '9'.ord
          case component
          when 0
            pan = pan * 10 + (ch - '0'.ord).to_i32
          when 1
            pad = pad * 10 + (ch - '0'.ord).to_i32
          when 2
            ph = ph * 10 + (ch - '0'.ord).to_i32
          when 3
            pv = pv * 10 + (ch - '0'.ord).to_i32
          end
        else
          break
        end
        n += 1
      end

      {Raster.new(pan, pad, ph, pv), n}
    end

    def self.decode_repeat(data : Bytes) : {Repeat, Int32}
      r = Repeat.new(0, '\0')
      n = 0
      return {r, n} if data.empty? || data[0] != RepeatIntroducer.ord

      # Minimum length is 3: introducer, at least one digit, and a character
      if data.size < 3
        return {r, n}
      end

      n = 1
      count = 0
      while n < data.size && data[n] >= '0'.ord && data[n] <= '9'.ord
        count = count * 10 + (data[n] - '0'.ord).to_i32
        n += 1
      end

      # If we reached end of data without finding a non-digit character
      if n >= data.size
        return {r, 0}
      end

      r = Repeat.new(count, data[n].chr)
      n += 1
      {r, n}
    end

    private def self.palval(n : Int32, a : Int32, m : Int32) : Int32
      (n * a + m // 2) // m
    end

    def self.sixel_rgb(r : Int32, g : Int32, b : Int32) : Ansi::Color
      Ansi::Color.new(
        palval(r, 0xff, 100).to_u8,
        palval(g, 0xff, 100).to_u8,
        palval(b, 0xff, 100).to_u8,
        0xFF_u8
      )
    end

    def self.sixel_hls(h : Int32, l : Int32, s : Int32) : Ansi::Color
      # Use Colorful library for HSL to RGB conversion (matches Go's colorful.Hsl)
      hue = h.to_f64
      saturation = s.to_f64 / 100.0
      lightness = l.to_f64 / 100.0
      colorful_color = Colorful::Color.hsl(hue, saturation, lightness)
      # Convert from Float64 0-1 to UInt8 0-255
      r = (colorful_color.r * 255.0).round.to_i.clamp(0, 255)
      g = (colorful_color.g * 255.0).round.to_i.clamp(0, 255)
      b = (colorful_color.b * 255.0).round.to_i.clamp(0, 255)
      Ansi::Color.new(r.to_u8, g.to_u8, b.to_u8, 0xFF_u8)
    end

    def self.convert_channel(c16 : UInt32) : UInt32
      (c16 + 328_u32) * 100_u32 / 0xffff_u32
    end

    struct Color
      getter pc : Int32
      getter pu : Int32
      getter px : Int32
      getter py : Int32
      getter pz : Int32

      def initialize(@pc : Int32 = 0, @pu : Int32 = 0, @px : Int32 = 0, @py : Int32 = 0, @pz : Int32 = 0)
      end

      def to_s : String
        String.build { |io| Sixel.write_color(io, @pc, @pu, @px, @py, @pz) }
      end

      def rgba : {UInt32, UInt32, UInt32, UInt32}
        case @pu
        when 1
          color = Sixel.sixel_hls(@px, @py, @pz)
        when 2
          color = Sixel.sixel_rgb(@px, @py, @pz)
        else
          # Default color map - for now just handle black for pc=0
          if @pc == 0
            return {0x0000_u32, 0x0000_u32, 0x0000_u32, 0xFFFF_u32}
          else
            # Fallback to black
            return {0x0000_u32, 0x0000_u32, 0x0000_u32, 0xFFFF_u32}
          end
        end
        {color.r.to_u32 * 0x101_u32, color.g.to_u32 * 0x101_u32, color.b.to_u32 * 0x101_u32, color.a.to_u32 * 0x101_u32}
      end
    end

    struct SixelColor
      getter red : UInt32
      getter green : UInt32
      getter blue : UInt32
      getter alpha : UInt32

      def initialize(@red : UInt32, @green : UInt32, @blue : UInt32, @alpha : UInt32)
      end
    end

    private def self.to_16bit(channel : UInt8) : UInt32
      (channel.to_u32 * 0x101_u32)
    end

    private def self.sixel_convert_color(color : Ansi::Color) : SixelColor
      SixelColor.new(
        convert_channel(to_16bit(color.r)),
        convert_channel(to_16bit(color.g)),
        convert_channel(to_16bit(color.b)),
        convert_channel(to_16bit(color.a))
      )
    end

    struct Palette
      getter palette_colors : Array(SixelColor)

      def initialize(@palette_colors : Array(SixelColor), @palette_indexes : Hash(SixelColor, Int32))
      end

      def color_index(color : SixelColor) : Int32
        @palette_indexes[color]
      end
    end

    private def self.new_palette(image : Ansi::Image, max_colors : Int32) : Palette
      pixel_counts = Hash(SixelColor, UInt64).new(0_u64)
      image.each_pixel do |_x, _y, color|
        converted = sixel_convert_color(color)
        pixel_counts[converted] += 1_u64
      end

      unique_colors = pixel_counts.keys
      palette_colors = quantize(unique_colors, pixel_counts, max_colors)
      palette_indexes = Hash(SixelColor, Int32).new

      unique_colors.each do |color|
        best_index = 0
        best_score = UInt32::MAX
        palette_colors.each_with_index do |palette_color, idx|
          dr = (color.red - palette_color.red)
          dg = (color.green - palette_color.green)
          db = (color.blue - palette_color.blue)
          da = (color.alpha - palette_color.alpha)
          score = dr * dr + dg * dg + db * db + da * da
          if score < best_score
            best_score = score
            best_index = idx
          end
        end
        palette_indexes[color] = best_index
      end

      Palette.new(palette_colors, palette_indexes)
    end

    private enum QuantizationChannel
      Red
      Green
      Blue
      Alpha
    end

    private struct QuantizationCube
      getter start_index : Int32
      getter length : Int32
      getter slice_channel : QuantizationChannel
      getter score : UInt64
      getter pixel_count : UInt64

      def initialize(@start_index : Int32, @length : Int32, @slice_channel : QuantizationChannel, @score : UInt64, @pixel_count : UInt64)
      end
    end

    # ameba:disable Metrics/CyclomaticComplexity
    private def self.create_cube(unique_colors : Array(SixelColor), pixel_counts : Hash(SixelColor, UInt64), start_index : Int32, length : Int32) : QuantizationCube
      min_red = 0xffff_u32
      min_green = 0xffff_u32
      min_blue = 0xffff_u32
      min_alpha = 0xffff_u32
      max_red = 0_u32
      max_green = 0_u32
      max_blue = 0_u32
      max_alpha = 0_u32
      total_weight = 0_u64

      (start_index...(start_index + length)).each do |i|
        color = unique_colors[i]
        total_weight += pixel_counts[color]
        min_red = color.red if color.red < min_red
        max_red = color.red if color.red > max_red
        min_green = color.green if color.green < min_green
        max_green = color.green if color.green > max_green
        min_blue = color.blue if color.blue < min_blue
        max_blue = color.blue if color.blue > max_blue
        min_alpha = color.alpha if color.alpha < min_alpha
        max_alpha = color.alpha if color.alpha > max_alpha
      end

      d_red = max_red - min_red
      d_green = max_green - min_green
      d_blue = max_blue - min_blue
      d_alpha = max_alpha - min_alpha

      slice_channel = if d_red >= d_green && d_red >= d_blue && d_red >= d_alpha
                        QuantizationChannel::Red
                      elsif d_green >= d_blue && d_green >= d_alpha
                        QuantizationChannel::Green
                      elsif d_blue >= d_alpha
                        QuantizationChannel::Blue
                      else
                        QuantizationChannel::Alpha
                      end

      score = case slice_channel
              when QuantizationChannel::Red   then d_red
              when QuantizationChannel::Green then d_green
              when QuantizationChannel::Blue  then d_blue
              else                                 d_alpha
              end

      QuantizationCube.new(start_index, length, slice_channel, score.to_u64 * total_weight, total_weight)
    end

    private def self.quantize(unique_colors : Array(SixelColor), pixel_counts : Hash(SixelColor, UInt64), max_colors : Int32) : Array(SixelColor)
      return unique_colors if unique_colors.size <= max_colors

      cubes = [] of QuantizationCube
      cubes << create_cube(unique_colors, pixel_counts, 0, unique_colors.size)

      while cubes.size < max_colors
        cubes.sort_by! { |cube| -cube.score }
        cube = cubes.shift
        break unless cube

        segment = unique_colors[cube.start_index, cube.length]
        case cube.slice_channel
        when QuantizationChannel::Red
          segment.sort_by!(&.red)
        when QuantizationChannel::Green
          segment.sort_by!(&.green)
        when QuantizationChannel::Blue
          segment.sort_by!(&.blue)
        when QuantizationChannel::Alpha
          segment.sort_by!(&.alpha)
        end
        unique_colors[cube.start_index, cube.length] = segment

        count_so_far = pixel_counts[segment[0]]
        target = cube.pixel_count / 2
        left_length = 1
        (1...segment.size).each do |idx|
          color = segment[idx]
          weight = pixel_counts[color]
          break if count_so_far + weight > target
          count_so_far += weight
          left_length += 1
        end

        right_length = cube.length - left_length
        right_index = cube.start_index + left_length
        cubes << create_cube(unique_colors, pixel_counts, cube.start_index, left_length)
        cubes << create_cube(unique_colors, pixel_counts, right_index, right_length)
      end

      palette = [] of SixelColor
      cubes.each do |quant_cube|
        total_red = 0_u64
        total_green = 0_u64
        total_blue = 0_u64
        total_alpha = 0_u64
        total_count = 0_u64
        (quant_cube.start_index...(quant_cube.start_index + quant_cube.length)).each do |i|
          color = unique_colors[i]
          count = pixel_counts[color]
          total_red += color.red.to_u64 * count
          total_green += color.green.to_u64 * count
          total_blue += color.blue.to_u64 * count
          total_alpha += color.alpha.to_u64 * count
          total_count += count
        end
        palette << SixelColor.new(
          (total_red / total_count).to_u32,
          (total_green / total_count).to_u32,
          (total_blue / total_count).to_u32,
          (total_alpha / total_count).to_u32
        )
      end

      palette
    end

    class BitSet
      def initialize
        @words = [] of UInt64
      end

      def set(bit : Int32) : Nil
        return if bit < 0
        word_index = bit // 64
        bit_index = bit % 64
        ensure_capacity(word_index)
        @words[word_index] |= (1_u64 << bit_index)
      end

      def next_set(start_bit : Int32) : {Int32, Bool}
        return {0, false} if start_bit < 0
        word_index = start_bit // 64
        bit_index = start_bit % 64
        return {0, false} if word_index >= @words.size

        mask = @words[word_index] & (~0_u64 << bit_index)
        if mask != 0
          return {(word_index * 64 + mask.trailing_zeros).to_i, true}
        end

        (word_index + 1...@words.size).each do |idx|
          word = @words[idx]
          next if word == 0
          return {(idx * 64 + word.trailing_zeros).to_i, true}
        end

        {0, false}
      end

      def get_word64_at_bit(bit : Int32) : UInt64
        return 0_u64 if bit < 0
        word_index = bit // 64
        shift = bit % 64
        low = word_index < @words.size ? @words[word_index] : 0_u64
        return low if shift == 0
        high = (word_index + 1) < @words.size ? @words[word_index + 1] : 0_u64
        (low >> shift) | (high << (64 - shift))
      end

      private def ensure_capacity(word_index : Int32) : Nil
        while @words.size <= word_index
          @words << 0_u64
        end
      end
    end

    class Decoder
      def scan_size(data : Bytes) : {Int32, Int32}
        max_width = 0
        band_count = 0
        current_width = 0
        new_band = true

        i = 0
        while i < data.size
          b = data[i]
          case b
          when LineBreak.ord
            # LF
            current_width = 0
            # The image may end with an LF, so we shouldn't increment the band
            # count until we encounter a pixel
            new_band = true
          when CarriageReturn.ord
            # CR
            current_width = 0
          when RepeatIntroducer.ord, '?'.ord..'~'.ord
            count = 1
            if b == RepeatIntroducer.ord
              # Get the run length for the RLE operation
              repeat, n = Sixel.decode_repeat(data[i..])
              if n == 0
                return {max_width, band_count * 6}
              end

              # 1 is added in the loop
              i += n - 1
              count = repeat.count
            end

            current_width += count
            if new_band
              new_band = false
              band_count += 1
            end

            max_width = Math.max(max_width, current_width)
          end
          i += 1
        end

        {max_width, band_count * 6}
      end
    end

    class Encoder
      def encode(io : IO, image : Ansi::Image) : Nil
        return if image.width == 0 || image.height == 0

        Sixel.write_raster(io, 1, 1, image.width, image.height)
        palette = new_palette(image, MaxColors)

        palette.palette_colors.each_with_index do |color, idx|
          io << ColorIntroducer << idx << ";2;" << color.red << ';' << color.green << ';' << color.blue
        end

        builder = SixelBuilder.new(image.width, image.height, palette)
        image.each_pixel do |x, y, color|
          builder.set_color(x, y, color)
        end
        io << builder.generate_pixels
      end
    end

    class SixelBuilder
      def initialize(@width : Int32, @height : Int32, @palette : Palette)
        @pixel_bands = BitSet.new
        @image_data = String::Builder.new
        @repeat_count = 0
        @repeat_byte = '\0'
      end

      def band_height : Int32
        bands = @height / 6
        bands += 1 if (@height % 6) != 0
        bands
      end

      def set_color(x : Int32, y : Int32, color : Ansi::Color) : Nil
        band_y = y / 6
        palette_index = @palette.color_index(Sixel.sixel_convert_color(color))
        bit = band_height * @width * 6 * palette_index + band_y * @width * 6 + (x * 6) + (y % 6)
        @pixel_bands.set(bit)
      end

      def generate_pixels : String
        @image_data = String::Builder.new
        band_count = band_height

        band_count.times do |band_y|
          write_control_rune(LineBreak) if band_y > 0
          has_written_color = false

          @palette.palette_colors.size.times do |palette_index|
            next if @palette.palette_colors[palette_index].alpha < 1

            first_color_bit = band_height * @width * 6 * palette_index + band_y * @width * 6
            next_color_bit = first_color_bit + @width * 6
            first_set_bit, any_set = @pixel_bands.next_set(first_color_bit)
            next if !any_set || first_set_bit >= next_color_bit

            if has_written_color
              write_control_rune(CarriageReturn)
            end
            has_written_color = true

            write_control_rune(ColorIntroducer)
            @image_data << palette_index

            x = 0
            while x < @width
              bit = first_color_bit + (x * 6)
              word = @pixel_bands.get_word64_at_bit(bit)
              pixel1 = ((word & 63) + '?'.ord).to_u8.chr
              pixel2 = (((word >> 6) & 63) + '?'.ord).to_u8.chr
              pixel3 = (((word >> 12) & 63) + '?'.ord).to_u8.chr
              pixel4 = (((word >> 18) & 63) + '?'.ord).to_u8.chr

              write_image_rune(pixel1)
              break if x + 1 >= @width
              write_image_rune(pixel2)
              break if x + 2 >= @width
              write_image_rune(pixel3)
              break if x + 3 >= @width
              write_image_rune(pixel4)
              x += 4
            end

            end_repeat
          end
        end

        @image_data.to_s
      end

      private def write_control_rune(char : Char) : Nil
        end_repeat
        @image_data << char
      end

      private def write_image_rune(char : Char) : Nil
        if @repeat_byte == '\0'
          @repeat_byte = char
          @repeat_count = 1
          return
        end

        if @repeat_byte == char
          @repeat_count += 1
          return
        end

        end_repeat
        @repeat_byte = char
        @repeat_count = 1
      end

      private def end_repeat : Nil
        return if @repeat_count == 0
        if @repeat_count == 1
          @image_data << @repeat_byte
        else
          @image_data << RepeatIntroducer << @repeat_count << @repeat_byte
        end
        @repeat_count = 0
        @repeat_byte = '\0'
      end
    end
  end
end
