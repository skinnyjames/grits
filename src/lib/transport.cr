@[Link(ldflags: "-l:libgit2.so.1.3")]
lib LibGit

  enum SmartServiceT
    UploadpackLs = 1
    Uploadpack = 2
    ReceivepackLs = 3
    Receievepack = 4
  end

  struct FetchNegotiation
    refs : RemoteHead*
    refs_len : LibC::SizeT
    shallow_roots : Oid*
    shallow_roots_len : LibC::SizeT
    depth : LibC::Int
  end

  # TODO: add RemoteConnectOptions
  alias TransportConnectCb = (Transport*, LibC::Char*, LibC::Int, LibGit::RemoteConnectOptions* -> LibC::Int)
  alias TransportSetConnectOptsCb = (Transport*, LibGit::RemoteConnectOptions* -> LibC::Int)
  alias TransportCapabilitiesCb = (LibC::UInt*, Transport* -> LibC::Int)
  alias TransportLsCb = (LibGit::RemoteHead***, LibC::SizeT*, Transport* -> LibC::Int)
  # TODO: add Push: https://github.com/libgit2/libgit2/blob/f041a94e2c358e84adb5a0fe108288fcb3802970/src/libgit2/push.h#L30
  alias TransportPushCb = (Transport*, LibGit::Push* -> LibC::Int)
  alias TransportNegotiateFetchCb = (Transport*, Repository, FetchNegotiation* -> LibC::Int)
  # TODO: add Oidarray
  alias TransportShallowRootsCb = (LibGit::Oidarray*, Transport* -> LibC::Int)
  alias TransportDownloadPackCb = (Transport*, Repository, IndexerProgress* -> LibC::Int)


  struct Transport
    version : LibC::UInt
    connect : TransportConnectCb
    set_connect_opts : TransportSetConnectOptsCb
    capabilities : TransportCapabilitiesCb
    ls : TransportLsCb
    push : TransportPushCb
    negotiate_fetch : TransportNegotiateFetchCb
    shallow_roots : TransportShallowRootsCb
    download_pack : TransportDownloadPackCb
    is_connected : (Transport* -> LibC::Int)
    cancel : (Transport* -> Void)
    close : (Transport* -> LibC::Int)
    free : (Transport* -> Void)
  end

  fun transport_init = git_transport_init(opts : Transport*, version : LibC::UInt) : LibC::Int
  fun transport_new = git_transport_new(out : Transport**, owner : Remote*, url : LibC::Char*) : LibC::Int
  # https://github.com/libgit2/libgit2/blob/f041a94e2c358e84adb5a0fe108288fcb3802970/include/git2/sys/transport.h#L175
  fun transport_ssh_with_paths = git_transport_ssh_with_paths(out : Transport**, owner : Remote*, payload : Void*) : LibC::Int
  fun transport_register = git_transport_register(prefix : LibC::Char*, cb : TransportCb, param : Void*) : LibC::Int
  fun transport_unregister = git_transport_unregister(prefix : LibC::Char*) : LibC::Int

  fun transport_dummy = git_transport_dummy(out : Transport**, owner : Remote*, payload : Void*) : LibC::Int
  fun transport_local = git_transport_local(out : Transport**, owner : Remote*, payload : Void*) : LibC::Int
  fun transport_smart = git_transport_smart(out : Transport**, owner : Remote*, payload : Void*) : LibC::Int
  fun transport_smart_certificate_check = git_transport_smart_certificate_check(transport : Transport*, cert : Certificate, valid : LibC::Int, hostname : LibC::Char*) : LibC::Int
  fun transport_smart_credentials = git_transport_smart_credentials(out : Credential*, transport : Transport*, user : LibC::Char*, methods : LibC::Int) : LibC::Int
  fun transport_remote_connect_options = git_transport_remote_connect_options(out : RemoteConnectOptions*, transport : Transport*) : LibC::Int
  

  alias TransportCb = (Transport*, Remote, Void* -> LibC::Int)
  alias TransportMessageCb = (LibC::Char*, LibC::Int, Void* -> LibC::Int)
  alias TransportCertificateCheckCb = (Credential*, LibC::Char*, LibC::Char*, LibC::UInt, Void* -> LibC::Int)
  
end
