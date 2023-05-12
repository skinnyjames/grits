require "./spec_helper"

describe Grits::Worktree do
  it "a repo isn't a worktree by default" do
    Fixture.clone_default_http do |repo, path|
      repo.worktree?.should eq(false)
    end
  end
end