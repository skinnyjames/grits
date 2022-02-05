module Grits
  alias RefType = LibGit::RefT

  struct Reference
    include Mixins::Pointable
    include Mixins::Wrapper

    def self.name_valid?(name)
      LibGit.reference_is_valid_name(name) == 1
    end

    def initialize(@raw : LibGit::Reference); end

    def name
      String.new(LibGit.reference_name(to_unsafe))
    end

    def type
      LibGit.reference_type(to_unsafe)
    end

    def branch?
      LibGit.reference_is_branch(to_unsafe) == 1
    end

    def remote?
      LibGit.reference_is_remote(to_unsafe) == 1
    end

    def tag?
      LibGit.reference_is_tag(to_unsafe) == 1
    end

    def free
      LibGit.reference_free(to_unsafe)
    end

    def owner
      repo = LibGit.reference_owner(to_unsafe)
      dir = LibGit.repository_workdir(to_unsafe).chop
      Repo.new(repo, dir)
    end
  end
end
