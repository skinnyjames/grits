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
        puts "FIRST"
        oid =  Grits::Oid.from_sha("9e42356acd4909c7a10a79e2a778b753bee22ce6")
        puts "OID STRING: #{oid.string}"
        puts "OID STRING (X2): #{oid.string}"
        puts "OID STRING (x3): #{oid.string}"
        
        parent = repo.last_commit.sha

        author = { email: "sean@sean.com", name: "Sean Gregory", time: Time.utc }
        committer = author

        repo.index do |index|
          Fixture.write_file("#{repo.workdir}/something.text", "Hello World")
          index.add "something.text"

          Grits::Commit.create(repo,
            author: author,
            message: "Hello World",
            committer: committer,
            parents: [parent],
            tree: index.tree,
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

    it "saves to the repo" do
      author = Fixture.random_user
      committer = Fixture.random_user

      Fixture.init_repo(make: true) do |repo, path|
        repo.index do |index|
          tree = index.tree

          Fixture.write_file("#{path}/something.text", "Hello World")
          index.add "something.text"

          Grits::Commit.create(repo,
            author: author,
            message: "Hello World",
            committer: committer,
            parents: [] of String,
            tree: tree,
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
