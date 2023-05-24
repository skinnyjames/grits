@[Link(ldflags: "-l:libgit2.so.1.3")]
lib LibGit
  alias TransportCb = (Transport**, Remote, Void* -> LibC::Int)
end
