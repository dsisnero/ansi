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

  it "covers the minimum and latest supported Crystal versions" do
    content = File.read(File.join(__DIR__, "..", ".github", "workflows", "ci.yml"))
    content.includes?("matrix").should be_true
    content.includes?("1.19.1").should be_true
    content.includes?("latest").should be_true
  end

  it "caches dependencies" do
    content = File.read(File.join(__DIR__, "..", ".github", "workflows", "ci.yml"))
    content.includes?("actions/cache").should be_true
  end
end
