require "./spec_helper"

describe Grits::Branch do
  describe "#create" do
    it "creates a branch" do
      Fixture.clone_default_http do |repo, path|
        branch = repo.create_branch("foo")
        branch.checked_out?.should eq(false)
        branch.checkout

        repo.head.name.should eq(branch.ref.name)
        branch.checked_out?.should eq(true)
      end
    end

    it "sees conflicts in branches" do
    end
  end
end