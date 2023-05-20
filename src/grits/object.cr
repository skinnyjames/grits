module Grits
  class Object
    alias Type = LibGit::OType

    include Mixins::Pointable

    def self.lookup(repo : Repo, oid : Oid, type : Type)
      Error.giterr LibGit.object_lookup(out obj, repo.to_unsafe, oid.to_unsafe_ptr, type), "Cannot lookup object"
      new(obj)
    end

    def initialize(@raw : LibGit::Object); end

    def id
      Oid.new LibGit.object_id(to_unsafe)
    end

    def tree?
      type == Type::Tree
    end

    def commit?
      type == Type::Commit
    end

    def blob?
      type == Type::Commit
    end

    def tag?
      type == Type::Tag
    end

    def ofs_delta?
      type == Type::OfsDelta
    end

    def ref_delta?
      type == Type::RefDelta
    end

    def type
      LibGit.object_type(to_unsafe)
    end

    def finalize
      free
    end

    def free
      LibGit.object_free(to_unsafe)
    end

  end
end
