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
end
