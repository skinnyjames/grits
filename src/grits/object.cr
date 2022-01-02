module Grits
  struct Oid
    include Mixins::Pointable

    def self.from_sha(sha : String)
      if sha.size == 40
        Error.giterr LibGit.oid_fromstr(out str_value, sha), "Cannot find oid from sha"
        new(str_value)
      else
        Error.giterr LibGit.oid_fromstrn(out strn_value, sha, sha.size), "Cannot find oid from sha"
        new(strn_value)
      end
    end

    def initialize(@raw : LibGit::Oid); end
  end
end
