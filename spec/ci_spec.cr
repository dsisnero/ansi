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

  it "runs the latest supported Crystal version" do
    content = File.read(File.join(__DIR__, "..", ".github", "workflows", "ci.yml"))
    content.includes?("crystal: latest").should be_true
  end

  it "builds the lint tool instead of relying on a system-wide ameba" do
    content = File.read(File.join(__DIR__, "..", ".github", "workflows", "ci.yml"))
    content.includes?("make tools").should be_true
  end

  it "caches dependencies" do
    content = File.read(File.join(__DIR__, "..", ".github", "workflows", "ci.yml"))
    content.includes?("actions/cache").should be_true
  end
end
