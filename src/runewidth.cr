require "./runewidth_tables"

module Ansi
  # Width condition matching go-runewidth's default (strict emoji neutral) mode.
  class WcWidthOptions
    class_property? east_asian : Bool = ENV["RUNEWIDTH_EASTASIAN"]? == "1"
  end

  module RunewidthTables
    def self.in_table?(table : Array({Int32, Int32}), codepoint : Int32) : Bool
      bot = 0
      top = table.size - 1
      while top >= bot
        mid = (bot + top) >> 1
        first, last = table[mid]
        if codepoint < first
          top = mid - 1
        elsif codepoint > last
          bot = mid + 1
        else
          return true
        end
      end
      false
    end
  end
end
