require "./spec_helper"

describe Grits::Repo do
  describe "properties" do
    it "shows properties for a non-bare repo" do
      Fixture.init_repo(make: true) do |repo, path|
        repo.empty?.should eq(true)
        repo.head_unborn?.should eq(true)
        repo.path.should eq("#{path}/.git/")
        repo.workdir.should eq("#{path}/")
      end
    end

    it "shows properties for a bare repo" do
      Fixture.init_repo(make: true, bare: true) do |repo, path|
        repo.empty?.should eq(true)
        repo.head_unborn?.should eq(true)
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

  describe "#clone" do
    it "clones a repo with default settings" do
      Fixture.clone_repo("https://github.com/skinnyjames/graphlyte.git", "graphlyte") do |repo|
        repo.empty?.should eq(false)
      end
    end

    it "can track progress of the clone" do
      options = Grits::Cloning::CloneOptions.default
      options.checkout_options.on_progress do |path, completed, total|
        puts "Progress for #{path}: #{((completed / total) * 100).round(0)}"
      end
      Fixture.clone_repo("https://github.com/skinnyjames/graphlyte.git", "graphlyte2", options) do |repo|
        repo.empty?.should eq(false)
      end
    end
  end
end
