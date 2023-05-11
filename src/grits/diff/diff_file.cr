module Grits
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
end