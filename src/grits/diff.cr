module Grits
  struct Diff
    include Mixins::Pointable

    def initialize(@raw : LibGit::Diff*); end

    def delta(index : LibC::SizeT)
      DiffDelta.new LibGit.diff_get_delta(to_unsafe, index)
    end

    def free
      Error.giterr LibGit.diff_free(to_unsafe)
    end
  end

  struct DiffFile
    include Mixins::Pointable
    include Mixins::Wrapper

    def initialize(@raw : LibGit::DiffFile*); end

    wrap raw, flags
    wrap raw, mode
    wrap raw, is_abbrev
    wrap raw, size

    def mode
      LibGit::FilemodeT.new(to_unsafe.value.mode)
    end

    def empty?
      to_unsafe.null?
    end

    def id
      oid = pointerof(to_unsafe.oid)
      Oid.new(oid).id
    end

    def path
      String.new(to_unsafe.value.path)
    end
  end

  struct DiffFindOptions
    def self.default
      # really think about versioning in constants
      options = LibGit::DiffFindOptions.new
      Error.giterr LibGit.diff_find_options_init(pointerof(options), 1), "Couldn't init diff options"
      new(options)
    end

    def initialize(@raw : LibGit::DiffFindOptions); end
  end

  struct DiffDelta
    include Mixins::Wrapper
    def initialize(@raw : LibGit::DiffDelta*); end

    wrap raw, status
    wrap raw, flags

    def files_count
      to_unsafe.nfiles
    end

    def calculate_simliarity!(options = DiffFindOptions.default)
      Error.giterr LibGit.diff_find_similar(to_unsafe, options), "couldn't calculate similiarity"
    end

    def old_file
      file = pointerof(to_unsafe.old_file)
      DiffFile.new(file)
    end

    def new_file
      file = pointerof(to_unsafe.new_file)
      DiffFile.new(file)
    end
  end
end