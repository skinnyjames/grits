module Grits
  record DeltaData, new_file : DiffFileData?, old_file : DiffFileData?, files_count : Int64

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
end
