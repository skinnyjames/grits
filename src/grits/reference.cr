module Grits
  alias RefType = LibGit::RefT

  struct Reference
    include Mixins::Pointable
    include Mixins::Wrapper

    def self.lookup(repo : Repo, name : String)
      Error.giterr(LibGit.reference_lookup(out reference, repo.to_unsafe, name.to_unsafe), "Cannot locate reference #{name}")

      new(repo, reference)
    end

    def self.name_valid?(name)
      LibGit.reference_is_valid_name(name) == 1
    end

    getter :repo

    def initialize(@repo : Grits::Repo, @raw : LibGit::Reference); end

    def name
      String.new(LibGit.reference_name(to_unsafe))
    end

    def id
      Error.giterr(LibGit.reference_name_to_id(out id, repo, name), "Cannot get oid for #{name}")
      Oid.new(id)
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
