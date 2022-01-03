module Grits
  class Index
    include Mixins::Pointable

    def initialize(@raw : LibGit::Index, @repo : Grits::Repo); end

    def add(path : String) : Void
      add_file(path)
      write
    end

    def add_file(path : String) : Void
      Error.giterr LibGit.index_add_bypath(@raw, path), "Cannot add file #{path}"
    end

    def write : Bool
      Error.giterr LibGit.index_write(@raw), "Index could not be written"
      true
    end

    def default_tree
      Error.giterr LibGit.index_write_tree(out tree_oid, @raw), "Could not read tree from index"
      Tree.lookup(@repo, tree_oid)
    end

    def free
      LibGit.index_free(@raw)
    end
  end
end
