@[Link(ldflags: "-l:libgit2.so.1.3")]
lib LibGit
  DEFAULT_PORT = "9418"

  enum Direction
    Fetch = 0
    Push = 1
  end

  struct RemoteHead
    local : LibC::Int
    oid : Oid
    loid : Oid
    name : LibC::Char*
    symref_target : LibC::Char*
  end
end