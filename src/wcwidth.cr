require "uniwidth"

# Crystal does not expose Unicode general categories, but its generated
# category tables are available to methods defined inside `Unicode`. This is
# the equivalent of Go's `unicode.Mn`, `unicode.Me`, and `unicode.Cf` tables.
module Unicode
  # Returns whether the codepoint is a nonspacing mark, enclosing mark, or
  # format character. These never advance the cursor.
  #
  # :nodoc:
  def self.zero_width?(codepoint : Int32) : Bool
    category_in?(category_Mn, codepoint) ||
      category_in?(category_Me, codepoint) ||
      category_in?(category_Cf, codepoint)
  end

  private def self.category_in?(table : Array({Int32, Int32, Int32}), codepoint : Int32) : Bool
    bot = 0
    top = table.size - 1
    while top >= bot
      mid = (bot + top) >> 1
      lo, hi, stride = table[mid]
      if codepoint < lo
        top = mid - 1
      elsif codepoint > hi
        bot = mid + 1
      else
        return (codepoint - lo) % stride == 0
      end
    end
    false
  end
end

module Ansi
  # Returns the number of columns a single codepoint advances the cursor,
  # i.e. wcwidth(3).
  #
  # Nonspacing and enclosing marks, along with format characters such as ZWJ
  # and the variation selectors, never advance the cursor. The width shard
  # reports some of them, most notably the Indic combining marks, as single
  # width, so they are classified here instead.
  def self.wc_rune_width(codepoint : Int32) : Int32
    case
    when codepoint < 0x20, codepoint >= 0x7f && codepoint <= 0x9f
      # C0 and C1 controls, and DEL, don't print.
      0
    when codepoint < 0x7f
      # Printable ASCII. Everything above it can be East Asian Ambiguous, so
      # it has to go through the width shard.
      1
    when Unicode.zero_width?(codepoint)
      0
    else
      width = UnicodeCharWidth.width(codepoint)
      # The width shard's double-width table predates recent emoji blocks.
      # Fall back to the emoji table for emoji codepoints above U+1F900.
      if width == 1 && codepoint >= 0x1f900 && emoji_codepoint?(codepoint)
        width = 2
      end
      width
    end
  end

  # Returns the number of columns a grapheme cluster occupies under
  # [Method::WcWidth], which is the sum of the widths of its codepoints.
  #
  # Terminals that don't implement Unicode core mode (DEC mode 2027) advance
  # the cursor once per codepoint and know nothing about cluster boundaries.
  # So a cluster can be wider than the glyph it draws: ZWJ emoji sequences
  # take the columns of each emoji they join.
  def self.wc_cluster_width(s : String) : Int32
    width = 0
    s.each_char { |char| width += wc_rune_width(char.ord) }
    width
  end

  # :ditto:
  def self.wc_cluster_width(bytes : Bytes) : Int32
    wc_cluster_width(String.new(bytes))
  end
end
