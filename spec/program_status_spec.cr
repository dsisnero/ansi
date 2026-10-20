require "./spec_helper"

describe "Ansi program status functions" do
  describe ".set_program_status" do
    it "minimal" do
      Ansi.set_program_status(Ansi::ProgramStatus.new(state: Ansi::ProgramState::Working))
        .should eq "\e]7501;state=working\a"
    end

    it "spec example" do
      status = Ansi::ProgramStatus.new(
        state: Ansi::ProgramState::Blocked,
        kind: Ansi::ProgramStatusKind::Permission,
        app: "terraform",
        message: "Apply 3 to add, 1 to change, 0 to destroy?",
      )
      Ansi.set_program_status(status)
        .should eq "\e]7501;state=blocked:kind=permission:app=terraform:msg=" +
                   Base64.strict_encode("Apply 3 to add, 1 to change, 0 to destroy?") + "\a"
    end

    it "all keys" do
      status = Ansi::ProgramStatus.new(
        state: Ansi::ProgramState::Working,
        id: "us-east",
        title: "US East",
        progress: 40,
        has_progress: true,
        message: "Pushing image",
      )
      Ansi.set_program_status(status)
        .should eq "\e]7501;state=working:id=us-east:progress=40:title=" +
                   Base64.strict_encode("US East") + ":msg=" +
                   Base64.strict_encode("Pushing image") + "\a"
    end

    it "clamps progress" do
      status = Ansi::ProgramStatus.new(
        state: Ansi::ProgramState::Blocked,
        progress: 300,
        has_progress: true,
      )
      Ansi.set_program_status(status).should eq "\e]7501;state=blocked:progress=100\a"
    end

    it "includes zero progress" do
      status = Ansi::ProgramStatus.new(
        state: Ansi::ProgramState::Working,
        has_progress: true,
      )
      Ansi.set_program_status(status).should eq "\e]7501;state=working:progress=0\a"
    end

    it "ignores progress for done" do
      status = Ansi::ProgramStatus.new(
        state: Ansi::ProgramState::Done,
        progress: 50,
        has_progress: true,
      )
      Ansi.set_program_status(status).should eq "\e]7501;state=done\a"
    end

    it "ignores kind for working" do
      status = Ansi::ProgramStatus.new(
        state: Ansi::ProgramState::Working,
        kind: Ansi::ProgramStatusKind::Auth,
      )
      Ansi.set_program_status(status).should eq "\e]7501;state=working\a"
    end

    it "omits unknown kind" do
      status = Ansi::ProgramStatus.new(
        state: Ansi::ProgramState::Blocked,
        kind: Ansi::ProgramStatusKind.new("nope"),
      )
      Ansi.set_program_status(status).should eq "\e]7501;state=blocked\a"
    end

    it "omits invalid app" do
      status = Ansi::ProgramStatus.new(
        state: Ansi::ProgramState::Idle,
        app: "my app",
      )
      Ansi.set_program_status(status).should eq "\e]7501;state=idle\a"
    end

    it "strips control characters" do
      status = Ansi::ProgramStatus.new(
        state: Ansi::ProgramState::Error,
        message: "  a\n\tb\e]2;x\a \u009bc  ",
      )
      Ansi.set_program_status(status)
        .should eq "\e]7501;state=error:msg=" +
                   Base64.strict_encode("a b ]2;x   c") + "\a"
    end

    it "omits message with only control characters" do
      status = Ansi::ProgramStatus.new(
        state: Ansi::ProgramState::Error,
        message: "\n\n",
      )
      Ansi.set_program_status(status).should eq "\e]7501;state=error\a"
    end

    it "clear ignores fields" do
      status = Ansi::ProgramStatus.new(
        state: Ansi::ProgramState::Clear,
        app: "x",
        message: "y",
      )
      Ansi.set_program_status(status).should eq Ansi::ClearProgramStatus
    end

    it "returns empty for unknown state" do
      Ansi.set_program_status(Ansi::ProgramStatus.new(state: Ansi::ProgramState.new("busy"))).should eq ""
    end

    it "returns empty for invalid id character" do
      status = Ansi::ProgramStatus.new(state: Ansi::ProgramState::Idle, id: "a b")
      Ansi.set_program_status(status).should eq ""
    end

    it "returns empty for invalid id empty segment" do
      status = Ansi::ProgramStatus.new(state: Ansi::ProgramState::Idle, id: "a//b")
      Ansi.set_program_status(status).should eq ""
    end

    it "returns empty for invalid id depth" do
      status = Ansi::ProgramStatus.new(
        state: Ansi::ProgramState::Idle,
        id: "a/b/c/d/e/f/g/h/i",
      )
      Ansi.set_program_status(status).should eq ""
    end

    it "returns empty for invalid id segment length" do
      status = Ansi::ProgramStatus.new(
        state: Ansi::ProgramState::Idle,
        id: "a" * 33,
      )
      Ansi.set_program_status(status).should eq ""
    end

    it "supports nested ids" do
      status = Ansi::ProgramStatus.new(
        state: Ansi::ProgramState::Idle,
        id: "build/test",
      )
      Ansi.set_program_status(status).should eq "\e]7501;state=idle:id=build/test\a"
    end
  end

  describe ".program_status=" do
    it "accepts a program status" do
      status = Ansi::ProgramStatus.new(state: Ansi::ProgramState::Working)
      (Ansi.program_status = status).should eq "\e]7501;state=working\a"
    end
  end

  describe "program status truncation" do
    it "truncates on a UTF-8 boundary" do
      # 'é' is 2 bytes, so 2048 bytes would split the last rune.
      message = "x" + ("é" * 1100)
      seq = Ansi.set_program_status(
        Ansi::ProgramStatus.new(state: Ansi::ProgramState::Done, message: message),
      )
      enc = seq.lchop("\e]7501;state=done:msg=").rchop("\a")
      dec = Base64.decode(enc)
      dec.size.should eq 2047
      seq.bytesize.should be <= 4096
    end
  end

  describe ".clear_program_status_id" do
    it "clears everything for an empty id" do
      Ansi.clear_program_status_id("").should eq Ansi::ClearProgramStatus
    end

    it "clears a specific id" do
      Ansi.clear_program_status_id("eu-west")
        .should eq "\e]7501;state=clear:id=eu-west\a"
    end

    it "returns empty for an invalid id" do
      Ansi.clear_program_status_id("bad id").should eq ""
    end
  end

  describe "constants" do
    it "ClearProgramStatus is correct" do
      Ansi::ClearProgramStatus.should eq "\e]7501;state=clear\a"
    end

    it "RequestProgramStatusSupport is correct" do
      Ansi::RequestProgramStatusSupport.should eq "\e]7501;?\a"
    end
  end
end
