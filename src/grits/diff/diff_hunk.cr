module Grits
  record HunkData, new_lines : Int32, old_lines : Int32, new_start : Int32, old_start : Int32, header : String, delta : DeltaData

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
end
