module Grits
  record LineData, origin : Char, new_lineno : Int32, old_lineno : Int32, num_lines : Int64, content_offset : Int64, content : String, hunk : HunkData

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
