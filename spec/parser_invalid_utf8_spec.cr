require "./parser_support_spec"

include ParserSpecSupport

# Go decodes the bytes the state machine collected with utf8.DecodeRune, so an
# invalid sequence dispatches a single U+FFFD and the bytes it collected are
# consumed with it. These cases were verified against the vendored parser in
# vendor/x/ansi.
describe "Ansi::Parser invalid UTF-8 handling" do
  cases = [
    {
      name:     "invalid two-byte sequence",
      input:    Bytes[0xc2, 0x7e],
      expected: ['\u{FFFD}'] of DispatchItem,
    },
    {
      name:     "invalid two-byte sequence with an invalid continuation",
      input:    Bytes[0xc2, 0x41],
      expected: ['\u{FFFD}'] of DispatchItem,
    },
    {
      name:     "invalid three-byte sequence",
      input:    Bytes[0xe0, 0x80, 0x41],
      expected: ['\u{FFFD}'] of DispatchItem,
    },
    {
      name:     "invalid three-byte sequence drops its collected bytes",
      input:    Bytes[0xe0, 0x41, 0x42],
      expected: ['\u{FFFD}'] of DispatchItem,
    },
    {
      name:     "invalid four-byte sequence",
      input:    Bytes[0xf0, 0x80, 0x80, 0x41],
      expected: ['\u{FFFD}'] of DispatchItem,
    },
    {
      name:     "surrogate codepoint",
      input:    Bytes[0xed, 0xa0, 0x80],
      expected: ['\u{FFFD}'] of DispatchItem,
    },
    {
      name:     "valid two-byte sequence",
      input:    Bytes[0xc2, 0xa9],
      expected: ['©'] of DispatchItem,
    },
    {
      name:     "valid four-byte sequence",
      input:    Bytes[0xf0, 0x9f, 0x91, 0x8b],
      expected: ['👋'] of DispatchItem,
    },
  ]

  cases.each do |test_case|
    it test_case[:name] do
      dispatcher = TestDispatcher.new
      ParserSpecSupport.test_parser(dispatcher).parse(test_case[:input])
      dispatcher.dispatched.should eq test_case[:expected]
    end
  end
end
