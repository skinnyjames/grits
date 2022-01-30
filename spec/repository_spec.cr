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
      Fixture.clone_repo("https://github.com/skinnyjames/graphlyte.git",  Random::Secure.hex(3)) do |repo|
        repo.empty?.should eq(false)
      end
    end

    it "can authenticate on clone" do
      options = Grits::Cloning::CloneOptions.default
      options.fetch_options.on_credentials_acquire do |credential|
        credential.add_ssh_key(
          username: credential.username || "git",
          public_key_path: ENV["GITHUB_SSH_PUBLIC_KEY_PATH"],
          private_key_path: ENV["GITHUB_SSH_PRIVATE_KEY_PATH"],
        )
      end

      Fixture.clone_repo("git@github.com:skinnyjames/webdriver.git", Random::Secure.hex(3), options) {}
    end

    it "can track progress of the clone" do
      progresses = [] of Float64
      options = Grits::Cloning::CloneOptions.default
      options.checkout_options.on_progress do |path, completed, total|
         progresses << ((completed / total) * 100).round(2)
      end

      options.checkout_options.file_mode = 0o700
      options.checkout_options.dir_mode = 0o700

      Fixture.clone_repo("https://github.com/skinnyjames/graphlyte.git",  Random::Secure.hex(3), options) do |_, path|
        Dir.glob("#{path}/**/*") do |file|
          File.info(file).permissions.to_s.should contain("0o700")
        end
        progresses.should_not be_empty
        progresses.reduce(-1) do |memo, progress|
          progress.should be > memo
          progress
        end
      end
    end
  end
end
