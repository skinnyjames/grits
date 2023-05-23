@[Link(ldflags: "-l:libgit2.so.1.3")]
lib LibGit
  enum RemoteCapabilityT
    TipOid = (1 << 0)
    ReachableOid = (1 << 1)
  end

  fun remote_connect_options_dispose(opts : RemoteConnectOptions*) : Void
end