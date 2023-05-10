module Grits
  class Tree
    include Mixins::Pointable
    getter :repo

    def self.lookup(repo : Grits::Repo, oid)
      Error.giterr LibGit.tree_lookup(out tree, repo.to_unsafe, pointerof(oid)), "Cannot find tree from id"
      new(tree, repo)
    end

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

    def free
      LibGit.tree_free(to_unsafe)
    end
  end
end
