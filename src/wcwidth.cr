require "uniwidth"

# Crystal does not expose Unicode general categories, but its generated
# category tables are available to methods defined inside `Unicode`. This is
# the equivalent of Go's `unicode.Mn`, `unicode.Me`, and `unicode.Cf` tables.
require "unicode_width"

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
    return 0 if codepoint < 0x20 || (codepoint >= 0x7f && codepoint <= 0x9f)
    return 0 if Unicode.zero_width?(codepoint)
    return 0 if legacy_zero_width?(codepoint)

    if UnicodeCharWidth.default_condition.east_asian && UnicodeCharWidth.ambiguous?(codepoint)
      2
    else
      width = UnicodeWidth.width(codepoint.chr)
      width > 0 ? width : 1
    end
  end

  # uniwidth already knows about combining marks that Go's runewidth table
  # treats as zero width, but it also zeroes Hangul Jamo and U+1734, which Go
  # measures as one column when they stand alone.
  private def self.legacy_zero_width?(codepoint : Int32) : Bool
    return false if codepoint >= 0x1160 && codepoint <= 0x11ff
    return false if codepoint == 0x1734

    UnicodeCharWidth.width(codepoint) == 0
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
