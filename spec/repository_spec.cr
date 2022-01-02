require "./spec_helper"

describe Grits::Repo do
  describe "properties" do
    it "shows properties for a non-bare repo" do
      Fixture.init_repo(make: true) do |repo, path|
        repo.empty?.should eq(true)
        repo.head_unborn?.should eq(true)
        # repo.head_detached?.should eq(false)

        repo.path.should eq("#{path}/.git/")
        repo.workdir.should eq("#{path}/")
      end
    end

    it "shows properties for a bare repo" do
      Fixture.init_repo(make: true, bare: true) do |repo, path|
        repo.empty?.should eq(true)
        repo.head_unborn?.should eq(true)
        # repo.head_detached?.should eq(false)
        repo.path.should eq("#{path}/")
        expect_raises(Grits::Error::Generic, /is the repository bare?/) do
          repo.workdir
        end
      end
    end
  end

  describe "#open" do
    it "opens a repo that already exists" do
      Fixture.init_repo(make: true) do |init, path|
        repo = Grits::Repo.open(path)
        repo.workdir.should eq(init.workdir)
        repo.bare?.should eq(init.bare?)
        repo.empty?.should eq(init.empty?)
        repo.head_unborn?.should eq(init.head_unborn?)
      end
    end
  end
end
