# ansi

`ansi` is a Crystal library for generating and parsing ANSI terminal escape
sequences. It is a Crystal port of `vendor/x/ansi` (Go) and includes helpers for
colors, styles, cursor control, modes, mouse/keyboard protocols, images
(Kitty, iTerm2, Sixel), grapheme cluster segmentation, and sequence
parsing/decoding utilities. Width measurement and segmentation follow the same
Unicode 17 tables the Go source uses.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     ansi:
       github: dsisnero/ansi
   ```

2. Run `shards install`

## Usage

```crystal
require "ansi"
```

Examples:

```crystal
# Colors and styles
puts Ansi.sgr(Ansi::AttrBold, Ansi::AttrBlueForegroundColor) + "Hello" + Ansi::ResetStyle

# Cursor movement
print Ansi.cursor_up(2)
print Ansi.cursor_forward(10)

# Clipboard
print Ansi.set_system_clipboard("hello")

# Kitty graphics
payload = "...".to_slice
print Ansi.kitty_graphics(payload)

# Width and grapheme clusters (ANSI escapes are skipped, clusters are measured)
Ansi.string_width("\e[31mこんにちは\e[0m")  # => 10
Ansi.string_width_wc("स्ते")                # => 2 (per code point)
Ansi.each_grapheme_cluster("a👋b") { |cluster, width| puts "#{cluster} #{width}" }

# Terminal input decoders do not apply GB9c, so a virama ends a segment:
Ansi.each_grapheme_cluster("स्ते", incb: false) { |cluster, _w| ... } # "स्", "ते"
```


## Development

Run the checks:

```bash
make build
make format
make lint
make test
make parity   # drift checks against the pinned vendor/x/ansi checkout
```

See [docs/development.md](docs/development.md) for setup, the vendored upstream
checkout, and the porting loop.

## Docs

- [Resuming work](docs/resuming.md)
- [Architecture](docs/architecture.md)
- [Development](docs/development.md)
- [Coding Guidelines](docs/coding-guidelines.md)
- [Testing](docs/testing.md)
- [PR Workflow](docs/pr-workflow.md)
- [Parity plan](plans/parity.md)
- [Port audit](docs/plan/audit.md)
- [Changelog](CHANGELOG.md)

## Contributing

1. Fork it (<https://github.com/dsisnero/ansi/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [your-name-here](https://github.com/dsisnero) - creator and maintainer
