module Grits
  struct Oid
    include Mixins::Pointable
    include Mixins::Wrapper

    def self.from_sha(sha : String)
      if sha.size == 40
        Error.giterr LibGit.oid_fromstr(out str_value, sha), "Cannot find oid from sha"
        new(pointerof(str_value))
      else
        Error.giterr LibGit.oid_fromstrn(out strn_value, sha, sha.size), "Cannot find oid from sha"
        new(pointerof(strn_value))
      end
    end

    def to_s(io)
      p = LibGit.oid_tostr_s(to_unsafe)
      io << String.new(p)
    end

    def initialize(@raw : LibGit::Oid*); end
  end

  struct Object
    alias Type = LibGit::OType

    include Mixins::Pointable

    def self.lookup(repo : Repo, oid : Oid, type : Type)
      Error.giterr LibGit.object_lookup(out obj, repo.to_unsafe, oid.to_unsafe, type), "Cannot lookup object"
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

    def type
      LibGit.object_type(to_unsafe)
    end

    def free
      LibGit.object_free(to_unsafe)
    end
  end
end
