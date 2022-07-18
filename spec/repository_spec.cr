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

    describe "#commondir" do
      it "should be the gitdir" do
        Fixture.init_repo(make: true) do |repo, path|
          repo.commondir.should eq("#{path}/.git/")
        end
      end

      pending "should be the gitdir when a worktree"
    end
  end

  describe "#config" do
    it "returns a snapshot" do
      Fixture.init_repo(make: true) do |repo, path|
        repo.config(snapshot: true) do |config|
          expect_raises(Grits::Error::Git, /readonly/) do
            config.set_bool("remote.foo.mirror", true)
          end
        end
      end
    end

    it "returns a config" do
      Fixture.init_repo(make: true) do |repo, path|
        repo.config do |config|
          config.set_bool("remote.foo.mirror", true)
          config.get_bool("remote.foo.mirror").should eq(true)
        end
      end
    end
  end

  describe "#discover" do
    it "walks parent directories" do
      Fixture.init_repo(make: true) do |repo, path|
        FileUtils.mkdir_p("#{path}/foo/bar/baz/buzz", 511)
        repo.discover("#{path}/foo/bar/baz/buzz").should eq("#{path}/.git/")
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
      Fixture.clone_repo("http://#{Fixture.host}:3000/skinnyjames/grits_empty_remote.git",  Random::Secure.hex(3)) do |repo|
        repo.empty?.should eq(false)
      end
    end

    it "checks out a branch" do
      options = Grits::CloneOptions.default
      options.checkout_branch = "foobar"
      expect_raises(Grits::Error::Git, message: "reference 'refs/remotes/origin/foobar' not found") do
        Fixture.clone_repo("http://#{Fixture.host}:3000/skinnyjames/grits_empty_remote.git",  Random::Secure.hex(3), options) {}
      end
    end

    it "on repository create" do
      path = Random::Secure.hex(3)
      options = Grits::CloneOptions.default
      options.on_repository_create do |path, bare|
        Grits::Repo.init("#{path}/hello", bare: bare)
      end

      Fixture.clone_repo("http://#{Fixture.host}:3000/skinnyjames/grits_empty_remote.git", path, options) do |repo|
        repo.workdir.should contain("#{path}/hello")
      end
    end

    it "on remote create" do
      url = "ssh://git@#{Fixture.host}:#{Fixture.ssh_port}/skinnyjames/grits_empty_remote.git"
      remote = "http://#{Fixture.host}:3000/skinnyjames/grits_empty_remote.git"

      options = Grits::CloneOptions.default
      options.on_remote_create do |repo, name, url|
        Grits::Remote.create(repo, "foo", remote)
      end

      Fixture.clone_repo(url, Random::Secure.hex(3), options) do |repo|
        repo.remote("foo").url.should eq(remote)
      end
    end

    describe "authentication" do
      it "via http" do
        options = Grits::CloneOptions.default
        options.fetch_options.on_credentials_acquire do |credential|
          credential.add_user_pass(
            username: "skinnyjames",
            password: Fixture.gitea_access_token
          )
        end

        Fixture.clone_repo("http://#{Fixture.host}:3000/skinnyjames/grits_private_remote.git", Random::Secure.hex(3), options) do |repo|
          repo.empty?.should eq(false)
        end
      end

      it "via ssh key paths" do
        options = Grits::CloneOptions.default
        options.fetch_options.on_credentials_acquire do |credential|
          credential.add_ssh_key(
            username: credential.username || "git",
            public_key_path: Fixture.gitea_public_key_path,
            private_key_path: Fixture.gitea_private_key_path,
          )
        end

        Fixture.clone_repo("ssh://git@#{Fixture.host}:#{Fixture.ssh_port}/skinnyjames/grits_empty_remote.git", Random::Secure.hex(3), options) do |repo|
          repo.empty?.should eq(false)
        end
      end

      it "via ssh keys" do
        options = Grits::CloneOptions.default
        options.fetch_options.on_credentials_acquire do |credential|
          credential.add_ssh_key(
            username: credential.username || "git",
            public_key: File.read(Fixture.gitea_public_key_path),
            private_key: File.read(Fixture.gitea_private_key_path),
          )
        end
        Fixture.clone_repo("ssh://git@#{Fixture.host}:#{Fixture.ssh_port}/skinnyjames/grits_empty_remote.git", Random::Secure.hex(3), options) do |repo|
          repo.empty?.should eq(false)
        end
      end

      it "via ssh agent" do
        begin
          `ssh-add #{Fixture.gitea_private_key_path}`
          options = Grits::CloneOptions.default
          options.fetch_options.on_credentials_acquire do |credential|
            credential.from_ssh_agent(username: credential.username || "git")
          end
          Fixture.clone_repo("ssh://git@#{Fixture.host}:#{Fixture.ssh_port}/skinnyjames/grits_empty_remote.git", Random::Secure.hex(3), options) do |repo|
            repo.empty?.should eq(false)
          end
        ensure
          `ssh-add -D #{Fixture.gitea_private_key_path}s`
        end
      end
    end

    describe "fetch options" do
      it "configures a proxy" do
        options = Grits::CloneOptions.default
        options.fetch_options.configure_proxy do |proxy|
          proxy.url = "https://foobaz"
          proxy.on_certificate_check do
            false
          end
          proxy.type = LibGit::ProxyT::Specified
          proxy
        end
        expect_raises(Grits::Error::Git, message: /failed to resolve address for foobaz/) do
          Fixture.clone_repo("https://#{Fixture.host}:3000/skinnyjames/grits_empty_remote.git",  Random::Secure.hex(3), options) {}
        end
      end

      describe "remote callbacks" do
        it "checks a certificate" do
          options = Grits::CloneOptions.default
          options.fetch_options.on_certificate_check do |cert, host, valid|
            false
          end
          expect_raises(Grits::Error::Git, message: "user rejected certificate for gitlab.com") do
            Fixture.clone_repo("https://gitlab.com/seanchristophergregory/grits.git",  Random::Secure.hex(3), options) {}
          end
        end

        it "updates with the tips?" do
          options = Grits::CloneOptions.default
          options.fetch_options.on_update_tips do |remote, oid, oid_2|
            remote.should eq("refs/remotes/origin/main")
          end
          Fixture.clone_repo("http://#{Fixture.host}:3000/skinnyjames/grits_empty_remote.git",  Random::Secure.hex(3), options) do |r|
            r.empty?.should eq(false)
          end
        end

        it "resolves the url" do
          options = Grits::CloneOptions.default
          options.fetch_options.on_resolve_url do |resolver|
            resolver.fetch?.should eq(true)
            resolver.set("http://foobar:3000/skinnyjames/grits_empty_remote")
          end
          expect_raises(Grits::Error::Git, message: /failed to resolve address for foobar/) do
            Fixture.clone_repo("http://#{Fixture.host}:3000/skinnyjames/grits_empty_remote.git",  Random::Secure.hex(3), options) {}
          end
        end

        describe "transfer progress" do
          it "tracks download progress" do
            progresses = [] of Float64
            options = Grits::CloneOptions.default
            options.fetch_options.on_transfer_progress do |indexer|
              progresses << indexer.percent_objects_downloaded
              true
            end
            Fixture.clone_repo("http://#{Fixture.host}:3000/skinnyjames/grits_empty_remote.git",  Random::Secure.hex(3), options) do |repo|
              repo.empty?.should eq(false)
              progresses.should_not be_empty
              progresses.reduce(-1) do |memo, progress|
                progress.should be >= memo
                progress
              end
            end
          end

          it "cancels downloads on return of false" do
            options = Grits::CloneOptions.default
            options.fetch_options.on_transfer_progress do |indexer|
              false
            end
            expect_raises(Grits::Error::Git, message: "indexer progress callback returned -1") do
              Fixture.clone_repo("http://#{Fixture.host}:3000/skinnyjames/grits_empty_remote.git",  Random::Secure.hex(3), options) {}
            end
          end
        end
      end
    end

    describe "checkout options" do
      it "can create an alternative target dir" do
        path = Fixture.tmp_path
        options = Grits::CloneOptions.default
        options.checkout_options.target_directory = path
        Fixture.clone_repo("http://#{Fixture.host}:3000/skinnyjames/grits_empty_remote.git",  Random::Secure.hex(3), options) do |repo|
          Dir.exists?(path).should eq(true)
        end
      end

      it "matches paths to checkout" do
        options = Grits::CloneOptions.default
        options.checkout_options.paths = ["foo"]
        Fixture.clone_repo("http://#{Fixture.host}:3000/skinnyjames/grits_empty_remote.git",  Random::Secure.hex(3), options) do |repo|
          Dir.entries(repo.workdir).should_not contain("file1")
        end
      end

      it "is notified with diff files" do
        options = Grits::CloneOptions.default
        options.checkout_options.on_notify do |why, path, baseline, target, workdir|
          why.should eq(Grits::CheckoutNotifyType::Untracked)
          path.should match(/file/)

          # only has a target diff
          baseline.empty?.should eq(true)
          target.empty?.should eq(false)
          workdir.empty?.should eq(true)

          target.path.should match(/file/)
          target.mode.should eq(Grits::FileModeType::Blob)
        end
        Fixture.clone_repo("http://#{Fixture.host}:3000/skinnyjames/grits_empty_remote.git",  Random::Secure.hex(3), options) {}
      end

      it "can track performance data" do
        options = Grits::CloneOptions.default
        options.checkout_options.on_performance_data do |perf|
          perf.mkdir_calls.should eq(0)
          perf.stat_calls.should eq(4)
          perf.chmod_calls.should eq(0)
        end
        Fixture.clone_repo("http://#{Fixture.host}:3000/skinnyjames/grits_empty_remote.git",  Random::Secure.hex(3), options) {}
      end

      it "can track progress of the clone" do
        progresses = [] of Float64
        options = Grits::CloneOptions.default
        options.checkout_options.on_progress do |path, completed, total|
           progresses << ((completed / total) * 100).round(2)
        end

        options.checkout_options.file_mode = 0o700
        options.checkout_options.dir_mode = 0o700

        Fixture.clone_repo("http://#{Fixture.host}:3000/skinnyjames/grits_empty_remote.git",  Random::Secure.hex(3), options) do |_, path|
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
end
