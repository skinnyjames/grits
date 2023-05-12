module Grits
  struct Worktree
    include Mixins::Pointable

    getter :repo
    def initialize(@raw : LibGit::Worktree, @repo : Repo); end

    def valid? : Bool
      code = LibGit.worktree_validate(to_unsafe)
      return true if code.zero?
      return false
    end

    def validate!
      Error.giterr(LibGit.worktree_validate(to_unsafe), "Tree not valid")
    end

    def free
      LibGit.worktree_free(to_unsafe)
    end
  end
end
