module Grits
  class Index
    include Mixins::Pointable

    def initialize(@raw : LibGit::Index, @repo : Grits::Repo); end

    def add(path : String) : Void
      add_file(path)
      write
    end

    def diff_workdir(options = DiffOptions.default) : Diff
      unsafe_opts = options.computed_unsafe
      unsafe_ptr = pointerof(unsafe_opts)

      Error.giterr LibGit.diff_index_to_workdir(out diff, @repo.to_unsafe, to_unsafe, unsafe_ptr), "Cannot diff index with workdir"

      Diff.new(diff)
    end

    def diff_workdir(options = DiffOptions.default, &)
      diff = diff_workdir(options)
      yield(diff)
      diff.free
    end

    def add_file(path : String) : Void
      Error.giterr LibGit.index_add_bypath(to_unsafe, path), "Cannot add file #{path}"
    end

    def write : Bool
      Error.giterr LibGit.index_write(to_unsafe), "Index could not be written"
      true
    end

    def write_tree
      int = LibGit.index_write_tree(out tree_oid, to_unsafe)
      if int.zero?
        Tree.lookup(@repo, tree_oid)
      else
        raise "Could not get write tree from index"
      end
    end

    def read_tree(tree : Tree)
      Error.giterr LibGit.index_read_tree(to_unsafe, tree.to_unsafe), "Could not read tree from index"
      self
    end

    def write_tree(&)
      local = write_tree
      begin
        yield(local)
      ensure
        local.free
      end
    end

    def free
      LibGit.index_free(to_unsafe)
    end
  end
end
