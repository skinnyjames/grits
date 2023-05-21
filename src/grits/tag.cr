module Grits
  class Tag
    include Mixins::Pointable

    def self.valid_name?(name : String) : Bool
      valid = uninitialized LibC::Int
      Error.giterr LibGit.tag_name_is_valid(pointerof(valid), name.to_unsafe), "Could not find validity of tag name"
      !valid.zero?
    end
    
    def self.lookup(repo : Grits::Repo, oid : Grits::Oid, *, name : String? = nil)
      resolved = name || "unknown tag"
      Error.giterr LibGit.tag_lookup(out tag, repo.to_unsafe, oid.to_unsafe_ptr), "Cannot lookup tag #{resolved}"

      new(repo, tag)
    end

    def initialize(@repo : Grits::Repo, @raw : LibGit::Tag); end

    def data
      TagData.new(name: name, sha: id.to_s, message: message)
    end

    def id
      oid_ptr = LibGit.tag_id(to_unsafe)
      Oid.new(oid_ptr.value)
    end

    def name
      String.new(LibGit.tag_name(to_unsafe))
    end

    def message
      String.new(LibGit.tag_message(to_unsafe))
    end

    def delete
      Error.giterr(LibGit.tag_delete(repo.to_unsafe, name.to_unsafe), "Cannot delete tag #{name}")
    end

    def free
      LibGit.tag_free(to_unsafe)
    end
  end
end
