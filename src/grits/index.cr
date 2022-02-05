module Grits
  class Index
    include Mixins::Pointable

    def initialize(@raw : LibGit::Index, @repo : Grits::Repo); end

    def add(path : String) : Void
      add_file(path)
      write
    end

    def add_file(path : String) : Void
      Error.giterr LibGit.index_add_bypath(to_unsafe, path), "Cannot add file #{path}"
    end

    def write : Bool
      Error.giterr LibGit.index_write(to_unsafe), "Index could not be written"
      true
    end

    def tree
      Error.giterr LibGit.index_write_tree(out tree_oid, to_unsafe), "Could not read tree from index"
      Tree.lookup(@repo, tree_oid)
    end

    def free
      LibGit.index_free(to_unsafe)
    end
  end
end
