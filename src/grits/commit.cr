module Grits
  class Commit
    include Mixins::Pointable

    def self.lookup(repo : Repo, id : Pointer(LibGit::Oid))
      Error.giterr LibGit.commit_lookup(out commit, repo.raw, id), "Can't find commit"
      new(commit)
    end

    def initialize(@raw : LibGit::Commit); end

    def message
      String.new LibGit.commit_message(@raw)
    end

    def free
      LibGit.commit_free(@raw)
    end
  end
end
