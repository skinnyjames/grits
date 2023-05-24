module Grits
  struct RemoteHead
    include Mixins::Pointable
    
    def initialize(@raw : LibGit::RemoteHead*); end

    def local? : Bool
      to_unsafe_value.local == 1
    end

    def oid : Oid
      Oid.new(to_unsafe_value.oid)
    end

    def loid : Oid
      Oid.new(to_unsafe_value.loid)
    end

    def name : String
      String.new(to_unsafe_value.name)
    end

    def symref_target : String
      String.new(to_unsafe_value.symref_target)
    end
  end

  struct FetchNegotiation
    include Mixins::Pointable
    include Mixins::Wrapper    
    def initialize(@raw : LibGit::FetchNegotiation*); end

    def remote_heads : Array(RemoteHead)
      slice = to_unsafe_value.refs.to_slice(to_unsafe_value.refs_len)
      slice.map {|head| RemoteHead.new(head) }.to_a
    end

    def shallow_roots : Array(Oid)
      slice = to_unsafe_value.shallow_roots.to_slice(to_unsafe_value.shallow_roots_len)
      slice.map { |oid| Oid.new(oid) }.to_a
    end

    def depth : Int32
      to_unsafe_value.depth
    end
  end
end
