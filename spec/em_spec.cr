require "./spec_helper"

describe "em cli" do
  it "gets the hot face" do
    s, out, err = run("", "hot face")
    err.should be_empty
    s.success?.should be_true
    `pbpaste`.should eq "🥵"
  end
end
