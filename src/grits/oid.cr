module Grits
  class Oid
    include Mixins::Pointable
    include Mixins::Wrapper

    @sha : String?

    def self.from_sha(sha : String)
      if sha.size == 40
        Error.giterr LibGit.oid_fromstr(out str_value, sha), "Cannot find oid from sha"
        new(str_value)
      else
        Error.giterr LibGit.oid_fromstrn(out strn_value, sha, sha.size), "Cannot find oid from sha"
        new(strn_value)
      end
    end

    def to_s(io)
      oid = to_unsafe
      p = LibGit.oid_tostr_s(pointerof(oid))
      io << String.new(p)
    end

    def string : String
      @sha ||= begin
        LibGit.oid_fromraw(out oid, to_unsafe.value.id)
        clone_id =  pointerof(oid)
    
        p = LibGit.oid_tostr_s(clone_id)
        String.new(p)
      end
    end

    def clone_id : LibGit::Oid*
      LibGit.oid_fromraw(out oid, to_unsafe.value.id)
      pointerof(oid)
    end

    def initialize(@raw : LibGit::Oid); end
  end
end
