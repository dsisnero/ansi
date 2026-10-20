require "./spec_helper"

describe "CI workflow" do
  it "runs the project quality gates" do
    path = File.join(__DIR__, "..", ".github", "workflows", "ci.yml")
    File.exists?(path).should be_true
    content = File.read(path)

    ["make build", "make format", "make lint", "make test"].each do |gate|
      content.includes?(gate).should be_true
    end
  end
end
