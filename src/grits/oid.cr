module Grits
  struct Oid
    include Mixins::Pointable
    include Mixins::Wrapper

    def self.from_sha(sha : String)
      if sha.size == 40
        Error.giterr LibGit.oid_fromstrp(out oid, sha), "Cannot find oid from sha"
        ptr = pointerof(oid)
        a = new(ptr)
        a
      else
        Error.giterr LibGit.oid_fromstrn(out strn_value, sha, sha.size), "Cannot find oid from sha"
        new(pointerof(strn_value))
      end
    end

    def string
      a = to_unsafe_ptr
      
      char = LibGit.oid_tostr_s(to_unsafe)
      IO::Memory.new(char.to_slice(40)).gets_to_end
    end

    def initialize(@raw : LibGit::Oid*); end
  end
end
