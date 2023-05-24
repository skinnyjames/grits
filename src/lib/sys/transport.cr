@[Link(ldflags: "-l:libgit2.so.1.3")]
lib LibGit
  TRANSPORT_VERSION = 1

  enum SmartServiceT
    UploadpackLs = 1
    Uploadpack = 2
    ReceivepackLs = 3
    Receievepack = 4
  end

  alias TransportMessageCb = (LibC::Char*, LibC::Int, Void* -> LibC::Int)
  alias TransportCertificateCheckCb = (GitCert*, LibC::Int, LibC::Char*, Void* -> LibC::Int)

  #alias TransportConnectCb = (Transport*, LibC::Char*, LibC::Int, LibGit::RemoteConnectOptions* -> LibC::Int)
  alias TransportSetCallbacks = (Transport*, TransportMessageCb, TransportMessageCb, TransportCertificateCheckCb, Void* -> LibC::Int)
  alias TransportSetCustomHeaders = (Transport*, Strarray* -> LibC::Int)


  alias TransportConnectCb = (Transport*, LibC::Char*, CredentialsAcquireCb, Void*, ProxyOptions*, LibC::Int, LibC::Int -> LibC::Int)
  #alias TransportSetConnectOptsCb = (Transport*, LibGit::RemoteConnectOptions* -> LibC::Int)
  alias TransportCapabilitiesCb = (LibC::UInt*, Transport* -> LibC::Int)
  alias TransportLsCb = (LibGit::RemoteHead***, LibC::SizeT*, Transport* -> LibC::Int)
  alias TransportPushCb = (Transport*, Push, RemoteCallbacks* -> LibC::Int)
  alias TransportNegotiateFetchCb = (Transport*, Repository, RemoteHead**, LibC::SizeT -> LibC::Int)

  alias TransportShallowRootsCb = (LibGit::Oidarray*, Transport* -> LibC::Int)
  alias TransportDownloadPackCb = (Transport*, Repository, IndexerProgress*, IndexerProgressCb, Void* -> LibC::Int)
  alias OidTypeCb = (OidT*, Transport -> LibC::Int)

  struct Transport
    version : LibC::UInt
    set_callbacks : TransportSetCallbacks
    set_custom_headers : TransportSetCustomHeaders
    connect : TransportConnectCb
    ls : TransportLsCb
    push : TransportPushCb
    negotiate_fetch : TransportNegotiateFetchCb
    download_pack : TransportDownloadPackCb
    is_connected : (Transport* -> LibC::Int)
    read_flags : (Transport*, LibC::Int* -> LibC::Int)
    cancel : (Transport* -> Void)
    close : (Transport* -> LibC::Int)
    free : (Transport* -> Void)
    payload : Void*
  end

  # struct Transport
  #   version : LibC::UInt
  #   connect : TransportConnectCb
  #   set_callbacks : TransportSetCallbacks
  #   capabilities : TransportCapabilitiesCb
  #   ls : TransportLsCb
  #   push : TransportPushCb
  #   oid_type : OidTypeCb
  #   negotiate_fetch : TransportNegotiateFetchCb
  #   shallow_roots : TransportShallowRootsCb
  #   download_pack : TransportDownloadPackCb
  #   is_connected : (Transport* -> LibC::Int)
  #   cancel : (Transport* -> Void)
  #   close : (Transport* -> LibC::Int)
  #   free : (Transport* -> Void)
  # end

  fun transport_init = git_transport_init(opts : Transport*, version : LibC::UInt) : LibC::Int
  fun transport_new = git_transport_new(out : Transport**, owner : Remote, url : LibC::Char*) : LibC::Int
  # https://github.com/libgit2/libgit2/blob/f041a94e2c358e84adb5a0fe108288fcb3802970/include/git2/sys/transport.h#L175
  fun transport_ssh_with_paths = git_transport_ssh_with_paths(out : Transport**, owner : Remote*, payload : Void*) : LibC::Int
  fun transport_register = git_transport_register(prefix : LibC::Char*, cb : TransportCb, param : Void*) : LibC::Int
  fun transport_unregister = git_transport_unregister(prefix : LibC::Char*) : LibC::Int

  fun transport_dummy = git_transport_dummy(out : Transport**, owner : Remote, payload : Void*) : LibC::Int
  fun transport_local = git_transport_local(out : Transport**, owner : Remote, payload : Void*) : LibC::Int
  fun transport_smart = git_transport_smart(out : Transport**, owner : Remote, payload : Void*) : LibC::Int
  fun transport_smart_certificate_check = git_transport_smart_certificate_check(transport : Transport*, cert : Certificate, valid : LibC::Int, hostname : LibC::Char*) : LibC::Int
  fun transport_smart_credentials = git_transport_smart_credentials(out : Credential*, transport : Transport*, user : LibC::Char*, methods : LibC::Int) : LibC::Int
  fun transport_remote_connect_options = git_transport_remote_connect_options(out : RemoteConnectOptions*, transport : Transport*) : LibC::Int
  
  alias SmartSubtransportActionCb = (SmartSubtransportStream**, SmartSubtransport*, LibC::Char*, SmartServiceT -> LibC::Int)
  alias SmartSubtransportStreamReadCb = (SmartSubtransportStream*, LibC::Char*, LibC::SizeT, LibC::SizeT* -> LibC::Int)
  alias SmartSubtransportStreamWriteCb = (SmartSubtransportStream*, LibC::Char*, LibC::SizeT -> LibC::Int)


  struct SmartSubtransport
    action : SmartSubtransportActionCb
    close : (SmartSubtransport* -> LibC::Int)
    free : (SmartSubtransport* -> Void)
    payload : Void*
  end

  struct SmartSubtransportStream
    subtransport : SmartSubtransport*
    read : SmartSubtransportStreamReadCb
    write : SmartSubtransportStreamWriteCb
    free : (SmartSubtransportStream* -> Void)
    payload : Void*
  end

  alias SmartSubtransportCb = (SmartSubtransport**, Transport*, Void* -> LibC::Int)

  #   /**
  #  * Definition for a "subtransport"
  #  *
  #  * The smart transport knows how to speak the git protocol, but it has no
  #  * knowledge of how to establish a connection between it and another endpoint,
  #  * or how to move data back and forth. For this, a subtransport interface is
  #  * declared, and the smart transport delegates this work to the subtransports.
  #  *
  #  * Three subtransports are provided by libgit2: ssh, git, http(s).
  #  *
  #  * Subtransports can either be RPC = 0 (persistent connection) or RPC = 1
  #  * (request/response). The smart transport handles the differences in its own
  #  * logic. The git subtransport is RPC = 0, while http is RPC = 1.
  #  */
  struct SmartSubtransportDefinition
    callback : SmartSubtransportCb
    rpc : LibC::UInt
    param : Void*
  end

  fun smart_subtransport = git_smart_subtransport_cb(out : SmartSubtransport**, transport : Transport*, param : Void*) : LibC::Int
  fun smart_subtransport_http = git_smart_subtransport_http(out : SmartSubtransport**, transport : Transport*, param : Void*) : LibC::Int
  fun smart_subtransport_git = git_smart_subtransport_git(out : SmartSubtransport**, transport : Transport*, param : Void*) : LibC::Int
  fun smart_subtransport_ssh = git_smart_subtransport_ssh(out : SmartSubtransport**, transport : Transport*, param : Void*) : LibC::Int
end
