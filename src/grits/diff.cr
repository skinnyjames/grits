require "./callbacks/diff_foreach_callbacks"

module Grits
  alias DiffBinaryType = LibGit::DiffBinaryT
  struct Diff
    include Mixins::Pointable

    def initialize(@raw : LibGit::Diff); end

    def file_deltas : Array(DiffDelta)
      deltas = [] of DiffDelta
      iterator = Grits::DiffIterator.new

      iterator.on_file do |delta, _|
        deltas << delta
      end

      iterate(iterator)

      deltas
    end

    def line_deltas
      lines = [] of NamedTuple(file: DiffDelta, hunk: DiffHunk, line: DiffLine)
      iterator = Grits::DiffIterator.new

      iterator.on_line do |file, hunk, line|
        lines << { file: file, hunk: hunk, line: line }
      end

      iterate(iterator)

      lines
    end

    def iterate(iterator : Grits::DiffIterator)
      iterator.execute(self)
    end

    def delta(index : LibC::SizeT)
      DiffDelta.new LibGit.diff_get_delta(to_unsafe, index)
    end

    def free
      LibGit.diff_free(to_unsafe)
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
    include Mixins::Pointable
    include Mixins::Wrapper
    def initialize(@raw : LibGit::DiffDelta*); end

    wrap raw, status
    wrap raw, flags

    def files_count
      to_unsafe.null? ? 0 : to_unsafe.value.nfiles
    end

    def calculate_simliarity!(options = DiffFindOptions.default)
      Error.giterr LibGit.diff_find_similar(to_unsafe, options), "couldn't calculate similiarity"
    end

    def old_file : DiffFile?
      return nil if to_unsafe.null?

      file = pointerof(to_unsafe.value.old_file)
      DiffFile.new(file)
    end

    def new_file : DiffFile?
      return nil if to_unsafe.null?

      file = pointerof(to_unsafe.new_file)
      DiffFile.new(file)
    end
  end

  struct DiffBinaryFile
    include Mixins::Wrapper

    def initialize(@raw : LibGit::DiffBinaryFile); end

    def type
      @raw.type.as(Grits::DiffBinaryType)
    end

    def empty?
      type == DiffBinaryType::None
    end

    def literal?
      type == DiffBinaryType::Literal
    end

    def delta?
      type == DiffBinaryType::Delta
    end

    def content
      String.new(@raw.data)
    end

    def length
      @raw.datalen.to_i64
    end
    
    def inflated_length
      @raw.inflatedlen.to_i64
    end
  end

  struct DiffBinary
    include Mixins::Wrapper

    def initialize(@raw : LibGit::DiffBinary*); end

    def contains_data?
      @raw.value.contains_data == 1
    end

    def old
      DiffBinaryFile.new(@raw.value.old_file)
    end

    def new
      DiffBinaryFile.new(@raw.value.new_file)
    end

  end

  struct DiffHunk
    include Mixins::Wrapper

    def initialize(@raw : LibGit::DiffHunk*); end

    wrap raw, old_start
    wrap raw, old_lines
    wrap raw, new_start
    wrap raw, new_lines
  
    def header
      String.new(@raw.header)
    end
  end

  class DiffLine
    include Mixins::Wrapper

    def initialize(@raw : LibGit::DiffLine*); end

    wrap raw, old_lineno
    wrap raw, new_lineno
    wrap raw, num_lines

    def added?
      old_lineno == -1
    end

    def deleted?
      new_lineno == -1
    end
    
    def content
      String.new(@raw.value.content)
    end

    def bytes_length
      @raw.value.content_len.to_i64
    end

    def content_offset
      @raw.value.content_offset.to_i64
    end
  end
end