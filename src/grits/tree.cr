module Grits
  class Tree
    include Mixins::Pointable

    def self.lookup(repo : Grits::Repo, oid)
      Error.giterr LibGit.tree_lookup(out tree, repo.raw, pointerof(oid)), "Cannot find tree from id"
      new(tree)
    end

    def initialize(@raw : LibGit::Tree); end
  end
end
