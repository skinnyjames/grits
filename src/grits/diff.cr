require "./callbacks/diff_foreach_callbacks"
require "./diff/*"

module Grits
  alias DiffDeltaType = LibGit::DeltaT
  alias DiffBinaryType = LibGit::DiffBinaryT
  struct Diff
    include Mixins::Pointable

    def self.status_code(type : DiffDeltaType)
      LibGit.diff_status_char(type).chr.to_s
    end

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
end
