module Grits
  alias IndexAddOption = LibGit::IndexAddOptionT

  class Index
    include Mixins::Pointable
    include Mixins::Util  

    def initialize(@raw : LibGit::Index, @repo : Grits::Repo); end

    def add(path : String) : Void
      add_file(path)
      write
    end

    def add(paths : Array(String), flags : Array(IndexAddOption) = [] of IndexAddOption, &notification_callback : String, String -> Bool?)
      add_files(paths, flags, &notification_callback)
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

    def add_files(path_expressions : Array(String), flags : Array(IndexAddOption) = [] of IndexAddOption, &notification : String, String -> Bool?)
      pathspec = convert_to_strarray(path_expressions)
      callback = ->(path : LibC::Char*, matching : LibC::Char*, payload : Void*) do
        notify_cb = Box(Proc(String, String, Bool?)).unbox(payload)
        path = String.new(path)
        match = String.new(matching)

        res = notify_cb.call(path, match)
        return 0 if res == true
        return 1 if res == false
        return -1
      end

      payload = Box(Proc(String, String, Bool?)).box(notification)

      Error.giterr LibGit.index_add_all(to_unsafe, pointerof(pathspec), flag_value(flags), callback, payload), "Add files failed"
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
