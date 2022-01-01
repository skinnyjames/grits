module Grits
  class Index
    include Mixins::Pointable

    def initialize(@raw : LibGit::Index); end

    def add(path : String) : Void
      Error.giterr LibGit.index_add_bypath(@raw, path), "Cannot add file #{path}"
    end

    def write : Bool
      Error.giterr LibGit.index_write(@raw), "Index could not be written"
      true
    end

    def free
      LibGit.index_free(@raw)
    end
  end
end
