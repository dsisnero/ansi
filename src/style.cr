module Ansi
  # Attr is a SGR (Select Graphic Rendition) style attribute.
  alias Attr = Int32

  # ResetStyle is a SGR (Select Graphic Rendition) style sequence that resets
  # all attributes.
  # See: https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters
  ResetStyle = "\e[m"

  # Style represents an ANSI SGR (Select Graphic Rendition) style.
  class Style
    getter attrs : Array(String)

    def initialize(attrs : Array(String))
      @attrs = attrs
    end

    # NewStyle returns a new style with the given attributes. Attributes are SGR
    # (Select Graphic Rendition) codes that control text formatting like bold,
    # italic, colors, etc.
    def self.new(attrs : Array(Attr)) : Style
      if attrs.empty?
        return Style.new([] of String)
      end

      strs = [] of String
      attrs.each do |a|
        str = ATTR_STRINGS[a]?
        if str
          strs << str
        else
          a = 0 if a < 0
          strs << a.to_s
        end
      end
      Style.new(strs)
    end

    # String returns the ANSI SGR (Select Graphic Rendition) style sequence for
    # the given style.
    def to_s : String
      if @attrs.empty?
        ResetStyle
      else
        "\e[" + @attrs.join(";") + "m"
      end
    end

    # Styled returns a styled string with the given style applied. The style is
    # applied at the beginning and reset at the end of the string.
    def styled(str : String) : String
      if @attrs.empty?
        str
      else
        to_s + str + ResetStyle
      end
    end
  end

  # SGR (Select Graphic Rendition) style attributes.
  # See: https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters
  AttrReset                        =   0
  AttrBold                         =   1
  AttrFaint                        =   2
  AttrItalic                       =   3
  AttrUnderline                    =   4
  AttrBlink                        =   5
  AttrRapidBlink                   =   6
  AttrReverse                      =   7
  AttrConceal                      =   8
  AttrStrikethrough                =   9
  AttrNormalIntensity              =  22
  AttrNoItalic                     =  23
  AttrNoUnderline                  =  24
  AttrNoBlink                      =  25
  AttrNoReverse                    =  27
  AttrNoConceal                    =  28
  AttrNoStrikethrough              =  29
  AttrBlackForegroundColor         =  30
  AttrRedForegroundColor           =  31
  AttrGreenForegroundColor         =  32
  AttrYellowForegroundColor        =  33
  AttrBlueForegroundColor          =  34
  AttrMagentaForegroundColor       =  35
  AttrCyanForegroundColor          =  36
  AttrWhiteForegroundColor         =  37
  AttrExtendedForegroundColor      =  38
  AttrDefaultForegroundColor       =  39
  AttrBlackBackgroundColor         =  40
  AttrRedBackgroundColor           =  41
  AttrGreenBackgroundColor         =  42
  AttrYellowBackgroundColor        =  43
  AttrBlueBackgroundColor          =  44
  AttrMagentaBackgroundColor       =  45
  AttrCyanBackgroundColor          =  46
  AttrWhiteBackgroundColor         =  47
  AttrExtendedBackgroundColor      =  48
  AttrDefaultBackgroundColor       =  49
  AttrExtendedUnderlineColor       =  58
  AttrDefaultUnderlineColor        =  59
  AttrBrightBlackForegroundColor   =  90
  AttrBrightRedForegroundColor     =  91
  AttrBrightGreenForegroundColor   =  92
  AttrBrightYellowForegroundColor  =  93
  AttrBrightBlueForegroundColor    =  94
  AttrBrightMagentaForegroundColor =  95
  AttrBrightCyanForegroundColor    =  96
  AttrBrightWhiteForegroundColor   =  97
  AttrBrightBlackBackgroundColor   = 100
  AttrBrightRedBackgroundColor     = 101
  AttrBrightGreenBackgroundColor   = 102
  AttrBrightYellowBackgroundColor  = 103
  AttrBrightBlueBackgroundColor    = 104
  AttrBrightMagentaBackgroundColor = 105
  AttrBrightCyanBackgroundColor    = 106
  AttrBrightWhiteBackgroundColor   = 107

  # Deprecated: use Attr* constants instead.
  ResetAttr                        = AttrReset
  BoldAttr                         = AttrBold
  FaintAttr                        = AttrFaint
  ItalicAttr                       = AttrItalic
  UnderlineAttr                    = AttrUnderline
  SlowBlinkAttr                    = AttrBlink
  RapidBlinkAttr                   = AttrRapidBlink
  ReverseAttr                      = AttrReverse
  ConcealAttr                      = AttrConceal
  StrikethroughAttr                = AttrStrikethrough
  NormalIntensityAttr              = AttrNormalIntensity
  NoItalicAttr                     = AttrNoItalic
  NoUnderlineAttr                  = AttrNoUnderline
  NoBlinkAttr                      = AttrNoBlink
  NoReverseAttr                    = AttrNoReverse
  NoConcealAttr                    = AttrNoConceal
  NoStrikethroughAttr              = AttrNoStrikethrough
  BlackForegroundColorAttr         = AttrBlackForegroundColor
  RedForegroundColorAttr           = AttrRedForegroundColor
  GreenForegroundColorAttr         = AttrGreenForegroundColor
  YellowForegroundColorAttr        = AttrYellowForegroundColor
  BlueForegroundColorAttr          = AttrBlueForegroundColor
  MagentaForegroundColorAttr       = AttrMagentaForegroundColor
  CyanForegroundColorAttr          = AttrCyanForegroundColor
  WhiteForegroundColorAttr         = AttrWhiteForegroundColor
  ExtendedForegroundColorAttr      = AttrExtendedForegroundColor
  DefaultForegroundColorAttr       = AttrDefaultForegroundColor
  BlackBackgroundColorAttr         = AttrBlackBackgroundColor
  RedBackgroundColorAttr           = AttrRedBackgroundColor
  GreenBackgroundColorAttr         = AttrGreenBackgroundColor
  YellowBackgroundColorAttr        = AttrYellowBackgroundColor
  BlueBackgroundColorAttr          = AttrBlueBackgroundColor
  MagentaBackgroundColorAttr       = AttrMagentaBackgroundColor
  CyanBackgroundColorAttr          = AttrCyanBackgroundColor
  WhiteBackgroundColorAttr         = AttrWhiteBackgroundColor
  ExtendedBackgroundColorAttr      = AttrExtendedBackgroundColor
  DefaultBackgroundColorAttr       = AttrDefaultBackgroundColor
  ExtendedUnderlineColorAttr       = AttrExtendedUnderlineColor
  DefaultUnderlineColorAttr        = AttrDefaultUnderlineColor
  BrightBlackForegroundColorAttr   = AttrBrightBlackForegroundColor
  BrightRedForegroundColorAttr     = AttrBrightRedForegroundColor
  BrightGreenForegroundColorAttr   = AttrBrightGreenForegroundColor
  BrightYellowForegroundColorAttr  = AttrBrightYellowForegroundColor
  BrightBlueForegroundColorAttr    = AttrBrightBlueForegroundColor
  BrightMagentaForegroundColorAttr = AttrBrightMagentaForegroundColor
  BrightCyanForegroundColorAttr    = AttrBrightCyanForegroundColor
  BrightWhiteForegroundColorAttr   = AttrBrightWhiteForegroundColor
  BrightBlackBackgroundColorAttr   = AttrBrightBlackBackgroundColor
  BrightRedBackgroundColorAttr     = AttrBrightRedBackgroundColor
  BrightGreenBackgroundColorAttr   = AttrBrightGreenBackgroundColor
  BrightYellowBackgroundColorAttr  = AttrBrightYellowBackgroundColor
  BrightBlueBackgroundColorAttr    = AttrBrightBlueBackgroundColor
  BrightMagentaBackgroundColorAttr = AttrBrightMagentaBackgroundColor
  BrightCyanBackgroundColorAttr    = AttrBrightCyanBackgroundColor
  BrightWhiteBackgroundColorAttr   = AttrBrightWhiteBackgroundColor

  # Mapping from Attr to string representation
  private ATTR_STRINGS = {
    AttrReset                        => "0",
    AttrBold                         => "1",
    AttrFaint                        => "2",
    AttrItalic                       => "3",
    AttrUnderline                    => "4",
    AttrBlink                        => "5",
    AttrRapidBlink                   => "6",
    AttrReverse                      => "7",
    AttrConceal                      => "8",
    AttrStrikethrough                => "9",
    AttrNormalIntensity              => "22",
    AttrNoItalic                     => "23",
    AttrNoUnderline                  => "24",
    AttrNoBlink                      => "25",
    AttrNoReverse                    => "27",
    AttrNoConceal                    => "28",
    AttrNoStrikethrough              => "29",
    AttrBlackForegroundColor         => "30",
    AttrRedForegroundColor           => "31",
    AttrGreenForegroundColor         => "32",
    AttrYellowForegroundColor        => "33",
    AttrBlueForegroundColor          => "34",
    AttrMagentaForegroundColor       => "35",
    AttrCyanForegroundColor          => "36",
    AttrWhiteForegroundColor         => "37",
    AttrExtendedForegroundColor      => "38",
    AttrDefaultForegroundColor       => "39",
    AttrBlackBackgroundColor         => "40",
    AttrRedBackgroundColor           => "41",
    AttrGreenBackgroundColor         => "42",
    AttrYellowBackgroundColor        => "43",
    AttrBlueBackgroundColor          => "44",
    AttrMagentaBackgroundColor       => "45",
    AttrCyanBackgroundColor          => "46",
    AttrWhiteBackgroundColor         => "47",
    AttrExtendedBackgroundColor      => "48",
    AttrDefaultBackgroundColor       => "49",
    AttrExtendedUnderlineColor       => "58",
    AttrDefaultUnderlineColor        => "59",
    AttrBrightBlackForegroundColor   => "90",
    AttrBrightRedForegroundColor     => "91",
    AttrBrightGreenForegroundColor   => "92",
    AttrBrightYellowForegroundColor  => "93",
    AttrBrightBlueForegroundColor    => "94",
    AttrBrightMagentaForegroundColor => "95",
    AttrBrightCyanForegroundColor    => "96",
    AttrBrightWhiteForegroundColor   => "97",
    AttrBrightBlackBackgroundColor   => "100",
    AttrBrightRedBackgroundColor     => "101",
    AttrBrightGreenBackgroundColor   => "102",
    AttrBrightYellowBackgroundColor  => "103",
    AttrBrightBlueBackgroundColor    => "104",
    AttrBrightMagentaBackgroundColor => "105",
    AttrBrightCyanBackgroundColor    => "106",
    AttrBrightWhiteBackgroundColor   => "107",
  }
end
