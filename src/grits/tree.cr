module Grits
  record TreeData, sha : String
  class Tree
    include Mixins::Pointable
    getter :repo

    def self.lookup(repo : Grits::Repo, oid)
      Error.giterr LibGit.tree_lookup(out tree, repo.to_unsafe, pointerof(oid)), "Cannot find tree from id"
      new(tree, repo)
    end

    def self.from_commit(commit : Grits::Commit)
      Error.giterr LibGit.commit_tree(out tree, commit.to_unsafe), "Cannot get tree from commit"
      new(tree, commit.repo)
    end

    getter :repo

    def initialize(@raw : LibGit::Tree, @repo : Repo); end

    def diff_workdir(options = DiffOptions.default, &)
      Error.giterr LibGit.diff_tree_to_workdir(out diff, repo.to_unsafe, to_unsafe, options.computed_unsafe_ptr), "Cannot fetch diff"
      grits_diff = Diff.new(diff)
      begin
        yield(grits_diff)
      ensure
        grits_diff.free
      end
    end

    def data
      TreeData.new(sha: id.to_s)
    end

    def commit(
      *,
      message : String,
      author : Commit::SignatureTuple,
      committer : Commit::SignatureTuple,
      encoding : String = "UTF-8",
      parents : Array(Commit),
      update_ref : String | Reference,
      &
    )
      Grits::Commit.create(
        repo,
        message: message,
        author: author,
        committer: committer,
        encoding: encoding,
        parents: parents,
        tree: self,
        update_ref: update_ref
      ) do |commit|
        yield(commit)
      end
    end

    def id : Oid
      Grits.get_tree_id(self)
    end

    def free
      LibGit.tree_free(to_unsafe)
    end
  end
end
