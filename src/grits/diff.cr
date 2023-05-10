require "./callbacks/diff_foreach_callbacks"

module Grits
  alias DiffDeltaType = LibGit::DeltaT
  alias DiffBinaryType = LibGit::DiffBinaryT
  struct Diff
    include Mixins::Pointable

    def initialize(@raw : LibGit::Diff); end

    def files : Array(DeltaData)
      deltas = [] of DeltaData
      iterator = Grits::DiffIterator.new

      iterator.on_file do |delta, _|
        deltas << delta.data
      end

      iterate(iterator)

      deltas
    end

    def hunks
      hunks = [] of HunkData
      iterator = Grits::DiffIterator.new

      iterator.on_hunk do |hunk|
        hunks << hunk.data
      end

      iterator.execute(self)

      hunks
    end

    def lines
      lines = [] of LineData
      iterator = Grits::DiffIterator.new

      iterator.on_line do |line|
        lines << line.data
      end

      iterator.execute(self)

      lines
    end

    def deltas : Int64
      LibGit.diff_num_deltas(to_unsafe).to_i64
    end

    def deltas(type : DiffDeltaType)
      LibGit.diff_num_deltas_of_type(to_unsafe, type).to_i64
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

  record DiffFileData, mode : LibGit::FilemodeT, path : String, id_length : Int32, sha : String

  struct DiffFile
    include Mixins::Pointable
    include Mixins::Wrapper

    def initialize(@raw : LibGit::DiffFile*); end

    wrap raw, flags
    wrap raw, mode
    wrap raw, is_abbrev
    wrap raw, size

    def data
      unless empty?
        DiffFileData.new(
          mode: mode,
          path: path,
          sha: id.to_s,
          id_length: @raw.value.id_abbrev      
        )
      end
    end

    def mode
      LibGit::FilemodeT.new(to_unsafe.value.mode)
    end

    def empty?
      to_unsafe.null?
    end

    def id
      Oid.new(@raw.value.id)
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

    def data
      DeltaData.new(
        files_count: files_count.to_i64,
        old_file: old_file.try(&.data),
        new_file: new_file.try(&.data)
      )
    end

    def files_count
      to_unsafe.null? ? 0 : to_unsafe.value.nfiles
    end

    def calculate_simliarity!(options = DiffFindOptions.default)
      Error.giterr LibGit.diff_find_similar(to_unsafe, options), "couldn't calculate similiarity"
    end

    def old_file : DiffFile?
      return nil if to_unsafe.null?

      oldf = to_unsafe.value.old_file
      file = pointerof(oldf)

      DiffFile.new(file)
    end

    def new_file : DiffFile?
      return nil if to_unsafe.null?

      nf = to_unsafe.value.new_file
      file = pointerof(nf)

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

    getter :delta

    def initialize(@raw : LibGit::DiffBinary*, delta : LibGit::DiffDelta*)
      @delta = DiffDelta.new(delta)
    end

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

  record DeltaData, new_file : DiffFileData?, old_file : DiffFileData?, files_count : Int64
  record HunkData, new_lines : Int32, old_lines : Int32, new_start : Int32, old_start : Int32, header : String, delta : DeltaData
  record LineData, origin : Char, new_lineno : Int32, old_lineno : Int32, num_lines : Int64, content_offset : Int64, content : String, hunk : HunkData

  struct DiffHunk
    include Mixins::Wrapper

    getter :delta

    def initialize(@raw : LibGit::DiffHunk*, delta : LibGit::DiffDelta*)
      @delta = DiffDelta.new(delta)
    end

    def data
      header = String.build do |io|
        io.write(@raw.value.header.to_slice)
      end


      HunkData.new(
        new_lines: @raw.value.new_lines,
        old_lines: @raw.value.old_lines,
        new_start: @raw.value.new_start,
        old_start: @raw.value.old_start,
        header: header,
        delta: @delta.data
      )
    end

    def new_lines : Int32
      @raw.value.new_lines
    end

    wrap raw, old_start
    wrap raw, old_lines
    wrap raw, new_start
  
    def header
      String.new(@raw.value.header.to_slice)
    end
  end

  struct DiffLine
    include Mixins::Wrapper

    getter :hunk, :origin, :old_lineno, :new_lineno, :num_lines, :content_offset

    def initialize(
      @raw : LibGit::DiffLine*,
      hunk : LibGit::DiffHunk*, 
      delta : LibGit::DiffDelta*
    )
      @hunk = DiffHunk.new(hunk, delta: delta)
    end

    def data
      str = String.build do |io|
        io.write(@raw.value.content.to_slice(@raw.value.content_len))
        io << '\0'
      end

      LineData.new(
        old_lineno: @raw.value.old_lineno.to_i32,
        new_lineno: @raw.value.new_lineno.to_i32,
        num_lines: @raw.value.num_lines.to_i64,
        origin: @raw.value.origin.chr,
        content_offset: @raw.value.content_offset.to_i64,
        content: str,
        hunk: @hunk.data
      )
    end

    def origin
      @raw.value.origin.chr
    end

    def added?
      old_lineno == -1
    end

    def deleted?
      new_lineno == -1
    end
    
    def content : String?
      @content
    end
  end
end
