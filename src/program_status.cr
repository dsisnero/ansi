module Ansi
  # ProgramState is the state of a program reported with the Program Status
  # Protocol (OSC 7501).
  #
  # See: https://www.superlogical.com/rex/docs/build/program-status
  struct ProgramState
    getter value : String

    def initialize(@value : String)
    end

    def to_s(io : IO) : Nil
      io << @value
    end

    def_equals @value
    def_hash @value

    # The program is at rest, waiting for the user's next instruction.
    Idle = new("idle")
    # The program is running.
    Working = new("working")
    # The program finished a piece of work and the result is ready to look at.
    Done = new("done")
    # The program cannot continue until the user does something.
    Blocked = new("blocked")
    # The program failed and stopped.
    Error = new("error")
    # Removes the addressed record and every record beneath it. With no id, it
    # removes every record on the terminal.
    Clear = new("clear")
  end

  # ProgramStatusKind says what a blocked program is waiting for.
  struct ProgramStatusKind
    getter value : String

    def initialize(@value : String)
    end

    def to_s(io : IO) : Nil
      io << @value
    end

    def_equals @value
    def_hash @value

    # The program waits for approval to do something.
    Permission = new("permission")
    # The user must type an answer.
    Question = new("question")
    # The program waits for a login, token, or credential.
    Auth = new("auth")
  end

  # ProgramStatus is a report of the Program Status Protocol (OSC 7501).
  #
  # Each report replaces its record completely, so fields such as `app` and
  # `title` should be included in every report.
  #
  # See: https://www.superlogical.com/rex/docs/build/program-status
  struct ProgramStatus
    # The program state. Required.
    property state : ProgramState
    # Addresses a record. Empty means the root record. It is a "/" separated
    # path of segments matching [A-Za-z0-9_.+-]{1,32}.
    property id : String
    # A stable machine-readable program name matching
    # [A-Za-z0-9_.+-]{1,32}. Invalid values are omitted.
    property app : String
    # Says what a blocked program waits for. Only used with
    # [ProgramState::Blocked].
    property kind : ProgramStatusKind?
    # A percentage between 0 and 100. Only used with [ProgramState::Working]
    # and [ProgramState::Blocked] when `has_progress` is true. Otherwise
    # progress is indeterminate.
    property progress : Int32
    # Whether [progress] is set.
    property? has_progress : Bool
    # A short human-readable label for the record.
    property title : String
    # One human-readable line describing the record.
    property message : String

    def initialize(
      @state : ProgramState,
      @id : String = "",
      @app : String = "",
      @kind : ProgramStatusKind? = nil,
      @progress : Int32 = 0,
      @has_progress : Bool = false,
      @title : String = "",
      @message : String = "",
    )
    end
  end

  # Program Status Protocol limits on decoded text.
  private PROGRAM_STATUS_MAX_TITLE   =  192
  private PROGRAM_STATUS_MAX_MESSAGE = 2048

  # ClearProgramStatus is a sequence that removes every program status record
  # on the terminal.
  #
  #	OSC 7501 ; state=clear BEL
  #
  # See: https://www.superlogical.com/rex/docs/build/program-status
  ClearProgramStatus = "\e]7501;state=clear\a"

  # RequestProgramStatusSupport is a sequence that asks the terminal whether it
  # supports the Program Status Protocol. A supporting terminal replies with
  # OSC 7501 ; ? ST.
  #
  #	OSC 7501 ; ? BEL
  #
  # See: https://www.superlogical.com/rex/docs/build/program-status
  RequestProgramStatusSupport = "\e]7501;?\a"

  # Returns a sequence that removes the record with the given id and every
  # record beneath it. An empty id removes every record. It returns an empty
  # string if the id is invalid.
  #
  #	OSC 7501 ; state=clear:id=Id BEL
  #
  # See: https://www.superlogical.com/rex/docs/build/program-status
  def self.clear_program_status_id(id : String) : String
    set_program_status(ProgramStatus.new(state: ProgramState::Clear, id: id))
  end

  # Sets the program status using the Program Status Protocol (OSC 7501).
  #
  # This is the Crystal-idiomatic writer form of [set_program_status].
  #
  # See: https://www.superlogical.com/rex/docs/build/program-status
  # ameba:disable Metrics/CyclomaticComplexity
  def self.program_status=(s : ProgramStatus) : String
    case s.state
    when ProgramState::Idle, ProgramState::Working, ProgramState::Done,
         ProgramState::Blocked, ProgramState::Error, ProgramState::Clear
    else
      return ""
    end
    return "" if !s.id.empty? && !valid_program_status_id(s.id)

    pairs = ["state=#{s.state}"] of String
    pairs << "id=#{s.id}" unless s.id.empty?
    return program_status_sequence(pairs) if s.state == ProgramState::Clear

    kind = s.kind
    if s.state == ProgramState::Blocked && kind && valid_program_status_kind(kind)
      pairs << "kind=#{kind}"
    end
    if s.has_progress? && (s.state == ProgramState::Working || s.state == ProgramState::Blocked)
      pairs << "progress=#{s.progress.clamp(0, 100)}"
    end
    if valid_program_status_segment(s.app)
      pairs << "app=#{s.app}"
    end
    title = program_status_text(s.title, PROGRAM_STATUS_MAX_TITLE)
    pairs << "title=#{title}" unless title.empty?
    message = program_status_text(s.message, PROGRAM_STATUS_MAX_MESSAGE)
    pairs << "msg=#{message}" unless message.empty?

    program_status_sequence(pairs)
  end

  # Returns a sequence that reports a program status using the Program Status
  # Protocol (OSC 7501).
  #
  #	OSC 7501 ; key=value:key=value BEL
  #
  # Terminals discard a whole report when any part of it is invalid, so the
  # report is sanitized: control characters in `title` and `message` are
  # replaced with spaces and the text is truncated to the protocol limits, and
  # an invalid `app`, or a `kind` or `progress` used with the wrong state, is
  # omitted. It returns an empty string if the state is unknown or the id is
  # invalid.
  #
  # This is the Go-compatible name for the [program_status=] writer. It is
  # generated by a macro because Ameba's Naming/AccessorMethodName rule cannot
  # associate the two, and an inline disable is not wanted.
  #
  # See: https://www.superlogical.com/rex/docs/build/program-status
  {% begin %}
    def self.set_program_status(s : ProgramStatus) : String
      self.program_status = s
    end
  {% end %}

  private def self.program_status_sequence(pairs : Array(String)) : String
    "\e]7501;#{pairs.join(':')}\a"
  end

  private def self.valid_program_status_kind(k : ProgramStatusKind) : Bool
    k == ProgramStatusKind::Permission ||
      k == ProgramStatusKind::Question ||
      k == ProgramStatusKind::Auth
  end

  # Sanitizes, truncates, and base64 encodes free text.
  private def self.program_status_text(s : String, limit : Int32) : String
    s = program_status_to_valid_utf8(s)
    sb = String::Builder.new
    space = false
    s.each_char do |char|
      ord = char.ord
      if ord < 0x20 || (ord >= 0x7f && ord <= 0x9f)
        unless space
          sb << ' '
          space = true
        end
        next
      end
      space = false
      sb << char
    end
    s = sb.to_s.strip
    if s.bytesize > limit
      s = s.byte_slice(0, limit)
      while !s.empty? && !s.valid_encoding?
        s = s.byte_slice(0, s.bytesize - 1)
      end
      s = s.strip
    end
    return "" if s.empty?

    Base64.strict_encode(s)
  end

  # Mirrors Go's strings.ToValidUTF8: every run of invalid bytes becomes one
  # replacement character.
  private def self.program_status_to_valid_utf8(s : String) : String
    return s if s.valid_encoding?

    String.build do |io|
      reader = Char::Reader.new(s)
      invalid = false
      while reader.has_next?
        start = reader.pos
        ch = reader.current_char
        reader.next_char
        if ch == Char::REPLACEMENT && reader.pos - start == 1
          unless invalid
            io << Char::REPLACEMENT
            invalid = true
          end
        else
          invalid = false
          io << ch
        end
      end
    end
  end

  private def self.valid_program_status_id(id : String) : Bool
    return false if id.bytesize > 128

    segs = id.split('/')
    return false if segs.size > 8

    segs.all? { |seg| valid_program_status_segment(seg) }
  end

  private def self.valid_program_status_segment(s : String) : Bool
    return false if s.bytesize < 1 || s.bytesize > 32

    s.each_byte do |byte|
      ch = byte.chr
      next if ch.ascii_alphanumeric? || ch == '_' || ch == '.' || ch == '+' || ch == '-'

      return false
    end
    true
  end
end
