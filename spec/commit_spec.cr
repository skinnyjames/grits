require "./spec_helper"

describe Grits::Commit do
  describe "::create" do
    it "saves to a cloned repo" do
      options = Grits::CloneOptions.default
      options.fetch_options.on_credentials_acquire do |credential|
        credential.add_ssh_key(
          username: credential.username || "git",
          public_key_path: Fixture.gitea_public_key_path,
          private_key_path: Fixture.gitea_private_key_path,
        )
      end

      Fixture.clone_repo("ssh://git@#{Fixture.host}:#{Fixture.ssh_port}/skinnyjames/grits_empty_remote.git", Random::Secure.hex(4), options) do |repo|
        repo.index do |stage|
          Fixture.write_file("#{repo.workdir}/something.text", "Hello World")
          stage.add "something.text"

          stage.write_tree do |tree|
            repo.commit_at("HEAD") do |parent|
              committer = author = { email: "sean@sean.com", name: "Sean Gregory", time: Time.utc }
              tree.commit(
                message: "Hello World",
                author: author,
                committer: committer,
                parents: [parent],
                update_ref: "HEAD"
              ) do |commit|
                repo.empty?.should eq(false)
                commit.message.should eq("Hello World")
    
                commit.author.name.should eq(author[:name])
                commit.author.email.should eq(author[:email])
                commit.author.time.should eq(Fixture.remove_milliseconds_from_time(author[:time]))
    
                commit.committer.name.should eq(committer[:name])
                commit.committer.email.should eq(committer[:email])
                commit.committer.time.should eq(Fixture.remove_milliseconds_from_time(committer[:time]))
              end
            end    
          end
        end
      end
    end

    it "readme example" do
      Fixture.clone_default_http do |repo, path|
        # create a new untracked file
        File.write("#{path}/new.txt", "Hello Grits.\n")

        repo.index do |stage|
          # add the new file to the staging index
          stage.add("new.txt")

          File.open("#{path}/new.txt", "a") do |io|
            io.print "Goodbye.\n"
          end

          # diff the changes
          stage.diff_workdir do |diff|
            puts diff.lines.map { |line| { line.hunk.header, line.content } } # => [{"@@ -1 +1,2 @@\n", "Hello Grits.\n"}, {"@@ -1 +1,2 @@\n", "Goodbye.\n"}]
          end

          # Write the index to a tree and yield it for commit
          stage.write_tree do |tree|
            repo.commit_at("HEAD") do |parent|
              committer = author = { 
                email: "sean@skinnyjames.net", 
                name: "Sean Gregory", 
                time: Time.utc 
              }

              tree.commit(
                author: author,
                message: "Hello World",
                committer: committer,
                parents: [parent],
                update_ref: "HEAD"
              ) do |commit|
                puts commit.message # => "Hello World"
              end
            end
          end
        end
      end
    end

    it "saves to the repo" do
      author = Fixture.random_user
      committer = Fixture.random_user

      Fixture.init_repo(make: true) do |repo, path|
        repo.index do |stage|
          Fixture.write_file("#{path}/something.text", "Hello World")
          stage.add "something.text"

          stage.write_tree do |tree|
            tree.commit(
              author: author,
              message: "Hello World",
              committer: committer,
              parents: [] of Grits::Commit,
              update_ref: "HEAD"
            ) do |commit|
              repo.empty?.should eq(false)
              commit.message.should eq("Hello World")
  
              commit.author.name.should eq(author[:name])
              commit.author.email.should eq(author[:email])
              commit.author.time.should eq(Fixture.remove_milliseconds_from_time(author[:time]))
  
              commit.committer.name.should eq(committer[:name])
              commit.committer.email.should eq(committer[:email])
              commit.committer.time.should eq(Fixture.remove_milliseconds_from_time(committer[:time]))
            end
          end
        end
      end
    end
  end
end
