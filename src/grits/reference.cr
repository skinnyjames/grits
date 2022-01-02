module Grits
  alias RefType = LibGit::RefT

  class Reference
    def self.name_valid?(name)
      LibGit.reference_is_valid_name(name) == 1
    end

    def initialize(@raw : LibGit::Reference); end

    def name
      String.new(LibGit.reference_name(@raw))
    end

    def type
      LibGit.reference_type(@raw) == 1
    end

    def branch?
      LibGit.reference_is_branch(@raw) == 1
    end

    def remote?
      LibGit.reference_is_remote(@raw) == 1
    end

    def tag?
      LibGit.reference_is_tag(@raw) == 1
    end

    def free
      LibGit.reference_free(@raw)
    end

    def owner
      repo = LibGit.reference_owner(@raw)
      dir = LibGit.repository_workdir(@raw).chop
      Repo.new(repo, dir)
    end
  end
end
