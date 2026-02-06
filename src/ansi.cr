require "./color"
require "./image"
require "./iterm2"
require "./kitty"
require "./sixel"
require "uri"
require "path"

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

  # SetPalette sets the palette color for the given index. The index is a 16
  # color index between 0 and 15. The color is a 24-bit RGB color.
  #
  #	OSC P n rrggbb BEL
  #
  # Where n is the color index in hex (0-f), and rrggbb is the color in
  # hexadecimal format (e.g., ff0000 for red).
  #
  # This sequence is specific to the Linux Console and may not work in other
  # terminal emulators.
  #
  # See https://man7.org/linux/man-pages/man4/console_codes.4.html
  def self.set_palette(index : Int32, color : Ansi::Color?) : String
    return "" if color.nil? || index < 0 || index > 15
    sprintf("\e]P%x%02x%02x%02x\a", index, color.r, color.g, color.b)
  end

  # ResetPalette resets the color palette to the default values.
  #
  # This sequence is specific to the Linux Console and may not work in other
  # terminal emulators.
  #
  # See https://man7.org/linux/man-pages/man4/console_codes.4.html
  ResetPalette = "\e]R\a"

  # SetIconNameWindowTitle returns a sequence for setting the icon name and
  # window title.
  #
  #	OSC 0 ; title ST
  #	OSC 0 ; title BEL
  #
  # See: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h2-Operating-System-Commands
  # ameba:disable Naming/AccessorMethodName
  def self.set_icon_name_window_title(s : String) : String
    "\e]0;#{s}\a"
  end

  # SetIconName returns a sequence for setting the icon name.
  #
  #	OSC 1 ; title ST
  #	OSC 1 ; title BEL
  #
  # See: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h2-Operating-System-Commands
  # ameba:disable Naming/AccessorMethodName
  def self.set_icon_name(s : String) : String
    "\e]1;#{s}\a"
  end

  # SetWindowTitle returns a sequence for setting the window title.
  #
  #	OSC 2 ; title ST
  #	OSC 2 ; title BEL
  #
  # See: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h2-Operating-System-Commands
  # ameba:disable Naming/AccessorMethodName
  def self.set_window_title(s : String) : String
    "\e]2;#{s}\a"
  end

  # DECSWT is a sequence for setting the window title.
  #
  # This is an alias for SetWindowTitle("1;<name>").
  # See: EK-VT520-RM 5–156 https://vt100.net/dec/ek-vt520-rm.pdf
  def self.decswt(name : String) : String
    set_window_title("1;" + name)
  end

  # DECSIN is a sequence for setting the icon name.
  #
  # This is an alias for SetWindowTitle("L;<name>").
  # See: EK-VT520-RM 5–134 https://vt100.net/dec/ek-vt520-rm.pdf
  def self.decsin(name : String) : String
    set_window_title("L;" + name)
  end

  # NotifyWorkingDirectory returns a sequence that notifies the terminal
  # of the current working directory.
  #
  #	OSC 7 ; Pt BEL
  #
  # Where Pt is a URL in the format "file://[host]/[path]".
  # Set host to "localhost" if this is a path on the local computer.
  #
  # See: https://wezfurlong.org/wezterm/shell-integration.html#osc-7-escape-sequence-to-set-the-working-directory
  # See: https://iterm2.com/documentation-escape-codes.html#:~:text=RemoteHost%20and%20CurrentDir%3A-,OSC%207,-%3B%20%5BPs%5D%20ST
  def self.notify_working_directory(host : String, *paths : String) : String
    joined_path = "/" + paths.join("/")
    uri = URI.new(
      scheme: "file",
      host: host,
      path: joined_path
    )
    "\e]7;#{uri}\a"
  end
end
