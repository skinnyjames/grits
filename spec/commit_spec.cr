require "./spec_helper"

describe Grits::Commit do
  describe "::create" do
    it "saves to the repo" do
      author = Fixture.random_user
      committer = Fixture.random_user

      Fixture.init_repo(make: true) do |repo, path|
        repo.index do |index|
          tree = index.default_tree

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
