module Grits
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
end
