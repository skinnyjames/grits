module Grits
  class Oid
    include Mixins::Pointable
    include Mixins::Wrapper

    @sha : String?

    # Fetch an Oid from a SHA hash
    #
    # If the SHA size is not equal to 40 chars
    # this method will use `git_oid_fromstrn`
    def self.from_sha(sha : String)
      if sha.size == 40
        Error.giterr LibGit.oid_fromstr(out str_value, sha), "Cannot find oid from sha"
        new(str_value)
      else
        Error.giterr LibGit.oid_fromstrn(out strn_value, sha, sha.size), "Cannot find oid from sha"
        new(strn_value)
      end
    end

    # Return the SHA hash for this Oid
    def to_s(io)
      oid = to_unsafe
      p = LibGit.oid_tostr_s(pointerof(oid))
      io << String.new(p)
    end

    protected def clone_id : LibGit::Oid*
      LibGit.oid_fromraw(out oid, to_unsafe.value.id)
      pointerof(oid)
    end

    def initialize(@raw : LibGit::Oid); end
  end
end
