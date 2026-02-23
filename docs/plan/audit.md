## ansi.go
(no structs or methods)

## ascii.go
(no structs or methods)

## background.go
### Structs
- `XRGBColor` [x]
  - Crystal: `src/color.cr`
- `XRGBAColor` [x]
  - Crystal: `src/color.cr`
### Methods
- `HexColor.RGBA` [x] (Crystal: `#rgba`)
- `HexColor.Hex` [x] (Crystal: `#hex`)
- `HexColor.String` [x] (Crystal: `#to_s`)
- `HexColor.color` [x] (Crystal: private `#color`)
- `XRGBColor.RGBA` [x] (Crystal: `#rgba`)
- `XRGBColor.String` [x] (Crystal: `#to_s`)
- `XRGBAColor.RGBA` [x] (Crystal: `#rgba`)
- `XRGBAColor.String` [x] (Crystal: `#to_s`)

## background_test.go
(no structs or methods)

## c0.go
(no structs or methods)

## c1.go
(no structs or methods)

## charset.go
(no structs or methods)

## clipboard.go
(no structs or methods)

## clipboard_test.go
(no structs or methods)

## color.go
### Structs
- `RGBColor` [x]
  - Crystal: `src/color.cr`
### Methods
- `BasicColor.RGBA` [x] (Crystal: `#rgba`)
- `IndexedColor.RGBA` [x] (Crystal: `#rgba`)
- `TrueColor.RGBA` [x] (Crystal: `#rgba`)
- `RGBColor.RGBA` [x] (Crystal: `#rgba`)

## color_test.go
(no structs or methods)

## ctrl.go
(no structs or methods)

## cursor.go
(no structs or methods)

## cwd.go
(no structs or methods)

## cwd_test.go
(no structs or methods)

## doc.go
(no structs or methods)

## finalterm.go
(no structs or methods)

## focus.go
(no structs or methods)

## gen.go
(no structs or methods)

## graphics.go
(no structs or methods)

## graphics_test.go
(no structs or methods)

## hyperlink.go
(no structs or methods)

## hyperlink_test.go
(no structs or methods)

## inband.go
(no structs or methods)

## iterm2/file.go
### Structs
- `file` [x] (Crystal: `File` struct, exported)
- `FileEnd` [x]
  - Crystal: `src/iterm2.cr`
### Methods
- `file.String` [x] (Crystal: `FileOptions#to_s` private)
- `File.String` [x] (Crystal: `File#to_s`)
- `MultipartFile.String` [x] (Crystal: `MultipartFile#to_s`)
- `FilePart.String` [x] (Crystal: `FilePart#to_s`)
- `FileEnd.String` [x] (Crystal: `FileEnd#to_s`)

## iterm2/file_test.go
(no structs or methods)

## iterm2/iterm2_test.go
(no structs or methods)

## iterm2.go
(no structs or methods)

## keypad.go
(no structs or methods)

## kitty/decoder.go
### Structs
- `Decoder` [x]
  - Crystal: `src/kitty.cr`
### Methods
- `*Decoder.Decode` [x]
- `*Decoder.decodeRGBA` [x]

## kitty/decoder_test.go
(no structs or methods)

## kitty/encoder.go
### Structs
- `Encoder` [x]
  - Crystal: `src/kitty.cr`
### Methods
- `*Encoder.Encode` [x]

## kitty/encoder_test.go
(no structs or methods)

## kitty/graphics.go
(no structs or methods)

## kitty/options.go
### Structs
- `Options` [x]
  - Crystal: `src/kitty.cr`
### Methods
- `*Options.Options` [x]
- `Options.String` [x]
- `Options.MarshalText` [x]
- `*Options.UnmarshalText` [x]

## kitty/options_test.go
(no structs or methods)

## kitty/writer.go
(no structs or methods)

## kitty/writer_test.go
(no structs or methods)

## kitty.go
(no structs or methods)

## method.go
### Methods
- `Method.StringWidth` [x]
- `Method.Truncate` [x]
- `Method.TruncateLeft` [x]
- `Method.Cut` [x]
- `Method.Hardwrap` [x]
- `Method.Wordwrap` [x]
- `Method.Wrap` [x]
- `Method.DecodeSequence` [x]
- `Method.DecodeSequenceInString` [x]

## mode.go
### Methods
- `ModeSetting.IsNotRecognized` [x]
- `ModeSetting.IsSet` [x]
- `ModeSetting.IsReset` [x]
- `ModeSetting.IsPermanentlySet` [x]
- `ModeSetting.IsPermanentlyReset` [x]
- `ANSIMode.Mode` [x]
- `DECMode.Mode` [x]

## mode_deprecated.go
(no structs or methods)

## mode_test.go
(no structs or methods)

## modes.go
### Methods
- `Modes.Get` [x]
- `Modes.Delete` [x]
- `Modes.Set` [x]
- `Modes.PermanentlySet` [x]
- `Modes.Reset` [x]
- `Modes.PermanentlyReset` [x]
- `Modes.IsSet` [x]
- `Modes.IsPermanentlySet` [x]
- `Modes.IsReset` [x]
- `Modes.IsPermanentlyReset` [x]

## mouse.go
### Methods
- `MouseButton.String` [x]

## mouse_test.go
### Structs
- `test` [ ]
- `test` [ ]

## notification.go
(no structs or methods)

## notification_test.go
(no structs or methods)

## palette.go
(no structs or methods)

## palette_test.go
(no structs or methods)

## parser/const.go
(no structs or methods)

## parser/seq.go
(no structs or methods)

## parser/transition_table.go
### Methods
- `TransitionTable.SetDefault` [x]
- `TransitionTable.AddOne` [x]
- `TransitionTable.AddMany` [x]
- `TransitionTable.AddRange` [x]
- `TransitionTable.Transition` [x]

## parser.go
### Structs
- `Parser` [x]
  - Crystal: `src/parser.cr`
### Methods
- `*Parser.SetParamsSize` [x] (Crystal: `#set_params_size`)
- `*Parser.SetDataSize` [x] (Crystal: `#set_data_size`)
- `*Parser.Params` [x] (Crystal: `#params` getter)
- `*Parser.Param` [x] (Crystal: `#param`)
- `*Parser.Command` [x] (Crystal: `#command`)
- `*Parser.Rune` [x] (Crystal: `#rune`)
- `*Parser.Control` [x] (Crystal: `#control`)
- `*Parser.Data` [x] (Crystal: `#data_slice`)
- `*Parser.Reset` [x] (Crystal: `#reset`)
- `*Parser.clear` [x] (Crystal: private `#clear`)
- `*Parser.State` [x] (Crystal: `#state` getter)
- `*Parser.StateName` [x] (Crystal: `#state_name`)
- `*Parser.Parse` [x] (Crystal: `#parse`)
- `*Parser.Advance` [x] (Crystal: `#advance`)
- `*Parser.collectRune` [x] (Crystal: private `#collect_rune`)
- `*Parser.advanceUtf8` [x] (Crystal: private `#advance_utf8`)
- `*Parser.advance` [x] (Crystal: private `#advance`? duplicate)
- `*Parser.parseStringCmd` [x] (Crystal: private `#parse_string_cmd`)
- `*Parser.performAction` [x] (Crystal: private `#perform_action`)

## parser_apc_test.go
(no structs or methods)

## parser_csi_test.go
(no structs or methods)

## parser_dcs_test.go
(no structs or methods)

## parser_decode.go
### Methods
- `Cmd.Prefix` [x] (Crystal: `ParserTransition.prefix`)
- `Cmd.Intermediate` [x] (Crystal: `ParserTransition.intermediate`)
- `Cmd.Final` [x] (Crystal: `ParserTransition.command`)
- `Param.Param` [x] (Crystal: `ParserTransition.param`)
- `Param.HasMore` [x] (Crystal: `ParserTransition.has_more`)

## parser_decode_test.go
### Structs
- `expectedSequence` [ ]

## parser_esc_test.go
(no structs or methods)

## parser_handler.go
### Structs
- `Handler` [x]
  - Crystal: `src/parser_handler.cr`
### Methods
- `Params.Param` [x] (Crystal: `Params#param`)
- `Params.ForEach` [x] (Crystal: `Params#for_each`)
- `*Parser.SetHandler` [x] (Crystal: `Parser#set_handler`)

## parser_osc_test.go
(no structs or methods)

## parser_sync.go
(no structs or methods)

## parser_test.go
### Structs
- `csiSequence` [ ]
- `dcsSequence` [ ]
- `testCase` [ ]
- `testDispatcher` [ ]
### Methods
- `*testDispatcher.dispatchRune` []
- `*testDispatcher.dispatchControl` []
- `*testDispatcher.dispatchEsc` []
- `*testDispatcher.dispatchCsi` []
- `*testDispatcher.dispatchDcs` []
- `*testDispatcher.dispatchOsc` []
- `*testDispatcher.dispatchApc` []

## passthrough.go
(no structs or methods)

## passthrough_test.go
(no structs or methods)

## paste.go
(no structs or methods)

## progress.go
(no structs or methods)

## progress_test.go
(no structs or methods)

## reset.go
(no structs or methods)

## screen.go
(no structs or methods)

## sgr.go
(no structs or methods)

## sgr_test.go
(no structs or methods)

## sixel/color.go
### Structs
- `Color` [x]
  - Crystal: `src/sixel.cr`
### Methods
- `Color.RGBA` [x] (Crystal: `#rgba`)

## sixel/color_test.go
(no structs or methods)

## sixel/decoder.go
### Structs
- `Decoder` [x]
  - Crystal: `src/sixel.cr`
### Methods
- `*Decoder.Decode` [x] (Crystal: `#decode`)
- `*Decoder.writePixel` [x] (Crystal: private `#write_pixel`)
- `*Decoder.scanSize` [x] (Crystal: `#scan_size`)
- `*Decoder.readError` [x] (Crystal: private `#read_error`)

## sixel/encoder.go
### Structs
- `Encoder` [x]
  - Crystal: `src/sixel.cr`
- `sixelBuilder` [x] (Crystal: `SixelBuilder`)
### Methods
- `*Encoder.Encode` [x] (Crystal: `#encode`)
- `*Encoder.encodePaletteColor` [x] (logic in `#encode`)
- `*sixelBuilder.BandHeight` [x] (Crystal: `#band_height`)
- `*sixelBuilder.SetColor` [x] (Crystal: `#set_color`)
- `*sixelBuilder.GeneratePixels` [x] (Crystal: `#generate_pixels`)
- `*sixelBuilder.writeImageRune` [x] (Crystal: private `#write_image_rune`)
- `*sixelBuilder.writeControlRune` [x] (Crystal: private `#write_control_rune`)
- `*sixelBuilder.flushRepeats` [x] (Crystal: private `#end_repeat`)

## sixel/palette.go
### Structs
- `sixelPalette` [x] (Crystal: `Palette`)
- `quantizationCube` [x] (Crystal: private `QuantizationCube`)
- `sixelColor` [x] (Crystal: `SixelColor`)
### Methods
- `*cubePriorityQueue.Push` [x] (Crystal: `Array#<<` with sorting, algorithm differs)
- `*cubePriorityQueue.Pop` [x] (Crystal: `Array#shift`, algorithm differs)
- `*cubePriorityQueue.Len` [x] (Crystal: `Array#size`, algorithm differs)
- `*cubePriorityQueue.Less` [x] (Crystal: sorting by score, algorithm differs)
- `*cubePriorityQueue.Swap` [x] (Crystal: sorting handles swapping)
- `*sixelPalette.createCube` [x] (Crystal: private `create_cube`)
- `*sixelPalette.quantize` [x] (Crystal: private `quantize`)
- `*sixelPalette.ColorIndex` [x] (Crystal: `Palette#color_index`)
- `*sixelPalette.loadColor` [x] (Crystal: functionality in `create_cube`)

## sixel/palette_sort.go
### Methods
- `*xorshift.Next` [ ] (not needed; Crystal uses deterministic sorting)

## sixel/palette_test.go
### Structs
- `testCase` [ ]

## sixel/raster.go
### Structs
- `Raster` [x]
  - Crystal: `src/sixel.cr`
### Methods
- `Raster.WriteTo` [x] (Crystal: `#write_to`)
- `Raster.String` [x] (Crystal: `#to_s`)

## sixel/raster_test.go
(no structs or methods)

## sixel/repeat.go
### Structs
- `Repeat` [x]
  - Crystal: `src/sixel.cr`
### Methods
- `Repeat.WriteTo` [x] (Crystal: `#write_to`)
- `Repeat.String` [x] (Crystal: `#to_s`)

## sixel/repeat_test.go
(no structs or methods)

## sixel/sixel_bench_test.go
(no structs or methods)

## sixel/sixel_test.go
(no structs or methods)

## status.go
### Methods
- `ANSIStatusReport.StatusReport` [x]
- `DECStatusReport.StatusReport` [x]

## style.go
### Methods
- `Style.String` [x]
- `Style.Styled` [x]
- `Style.Reset` [x]
- `Style.Bold` [x]
- `Style.Faint` [x]
- `Style.Italic` [x]
- `Style.Underline` [x]
- `Style.UnderlineStyle` [x]
- `Style.Blink` [x]
- `Style.RapidBlink` [x]
- `Style.Reverse` [x]
- `Style.Conceal` [x]
- `Style.Strikethrough` [x]
- `Style.Normal` [x]
- `Style.NoItalic` [x]
- `Style.NoUnderline` [x]
- `Style.NoBlink` [x]
- `Style.NoReverse` [x]
- `Style.NoConceal` [x]
- `Style.NoStrikethrough` [x]
- `Style.DefaultForegroundColor` [x]
- `Style.DefaultBackgroundColor` [x]
- `Style.DefaultUnderlineColor` [x]
- `Style.ForegroundColor` [x]
- `Style.BackgroundColor` [x]
- `Style.UnderlineColor` [x]

## style_test.go
(no structs or methods)

## termcap.go
(no structs or methods)

## title.go
(no structs or methods)

## title_test.go
(no structs or methods)

## truncate.go
(no structs or methods)

## truncate_test.go
(no structs or methods)

## urxvt.go
(no structs or methods)

## urxvt_test.go
(no structs or methods)

## util.go
(no structs or methods)

## width.go
(no structs or methods)

## width_test.go
(no structs or methods)

## winop.go
(no structs or methods)

## wrap.go
(no structs or methods)

## wrap_test.go
(no structs or methods)

## xterm.go
(no structs or methods)

