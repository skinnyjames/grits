@[Link("git2")]
lib LibGit
  type RepositoryCbPayload = Void*
  type RemoteCbPayload = Void*
  type NotifyCbPayload = Void*
  type ProgressCbPayload = Void*
  type PerfdataCbPayload = Void*
  type NotifyPayload = Void*
  type Credential = Void*
  type GenericPayload = Void*
  type Certificate = Void*
  type Transport = Void*

  enum CloneLocal
    Auto
    Local
    NoLocal
    LocalNoLinks
  end

  enum CheckoutNotify
    None
    Conflict
    Diry
    Updated
    Untracked
    Ignared
    All
  end

  enum RemoteCompletion
    Download
    Indexing
    Error
  end

  enum FetchPrune
    Unspecified
    Prune
    NoPrune
  end

  enum RemoteAutotagOption
    Unspecified
    Auto
    None
    All
  end

  enum Proxy
    None
    Auto
    Specified
  end

  alias RepositoryCb = (Repository*, LibC::Char*, LibC::Int, RepositoryCbPayload -> LibC::Int)
  alias RemoteCb = (Remote*, Repository, LibC::Char*, LibC::Char*, RemoteCbPayload -> LibC::Int)
  alias RemoteReadyCb = (Remote, LibC::Int, GenericPayload -> LibC::Int)
  alias CheckoutNotifyCb = (CheckoutNotify, LibC::Char*, DiffFile*, DiffFile*, DiffFile*, NotifyCbPayload -> LibC::Int)
  alias CheckoutProgressCb = (LibC::Char*, LibC::SizeT, LibC::SizeT, ProgressCbPayload -> Void)
  alias CheckoutPerfdataCb = (CheckoutPerfdata*, PerfdataCbPayload -> Void)
  alias CredentialsAcquireCb = (Credential*, LibC::Char*, LibC::Char*, LibC::UInt, GenericPayload -> LibC::Int)
  alias TransportCb = (Transport*, Remote, Void* -> LibC::Int)
  alias TransportMessageCb = (LibC::Char*, LibC::Int, GenericPayload -> LibC::Int)
  alias TransportCertificateCheckCb = (Certificate, LibC::Int, LibC::Char*, GenericPayload -> LibC::Int)
  alias IndexerProgressCb = (IndexerProgress*, GenericPayload -> LibC::Int)
  alias PushTransferProgressCb = (LibC::UInt, LibC::UInt, LibC::SizeT, GenericPayload -> LibC::Int)
  alias PushUpdateReferenceCb = (LibC::Char*, LibC::Char*, GenericPayload -> LibC::Int)
  alias PushNegotiationCb = (PushUpdate**, LibC::SizeT, GenericPayload -> LibC::Int)
  alias UrlResolveCb = (Buf*, LibC::Char*, LibC::Int, GenericPayload -> LibC::Int)

  struct RepositoryInitOptions
    version : LibC::UInt
    flags : Uint32T
    mode : Uint32T
    workdir_path : LibC::Char*
    description : LibC::Char*
    template_path : LibC::Char*
    initial_head : LibC::Char*
    origin_url : LibC::Char*
  end

  struct RemoteCallbacks
    version : LibC::UInt
    sideband_progress : TransportMessageCb # todo
    #completion :  Int* -> (RemoteCompletion) -> Void* #wrong
    credentials : CredentialsAcquireCb
    certificate_check : TransportCertificateCheckCb
    transfer_progress : IndexerProgressCb
    #update_tips : LibC::Char* # wrong
    pack_progress : (LibC::Int, Uint32T, Uint32T, GenericPayload -> LibC::Int)
    push_transfer_progress : PushTransferProgressCb
    push_update_reference : PushUpdateReferenceCb
    push_negotiation : PushNegotiationCb
    transport : TransportCb
    remote_ready : RemoteReadyCb
    payload : GenericPayload
    resolve_url : UrlResolveCb
  end

  struct ProxyOptions
    version : LibC::UInt
    type : Proxy
    url : LibC::Char*
    credentials : CredentialsAcquireCb
    certificate_check : TransportCertificateCheckCb
    payload : Void*
  end

  struct PushUpdate
    src_refname : LibC::Char*
    dst_refname : LibC::Char*
    src : Oid
    dst : Oid
  end

  struct CloneOptions
    version : LibC::UInt
    checkout_opts : CheckoutOptions
    fetch_opts : FetchOptions
    bare : LibC::Int
    local : CloneLocal
    checkout_branch : LibC::Char*
    repository_cb : RepositoryCb
    repository_cb_payload : RepositoryCbPayload
    remote_cb : RemoteCb
    remote_cb_payload : RemoteCbPayload
  end

  struct IndexerProgress
    total_objects : LibC::UInt
    indexed_objects : LibC::UInt
    recieved_objects : LibC::UInt
    local_objects : LibC::UInt
    total_deltas : LibC::UInt
    indexed_deltas : LibC::UInt
    recieved_bytes : LibC::SizeT
  end

  struct CheckoutPerfdata
    mkdir_calls : LibC::SizeT
    stat_calls : LibC::SizeT
    chmod_calls : LibC::SizeT
  end

  struct FetchOptions
    version : LibC::Int
    callbacks : RemoteCallbacks
    prune : FetchPrune
    update_fetchhead : LibC::Int
    download_tags : RemoteAutotagOption
    proxy_options : ProxyOptions
    custom_headers : Strarray
  end

  struct CheckoutOptions
    version : LibC::UInt
    checkout_strategy : LibC::UInt
    disable_filters : LibC::Int
    dir_mode : LibC::UInt
    file_mode : LibC::UInt
    file_open_flags : LibC::Int
    notify_flags : LibC::UInt
    notify_cb : CheckoutNotifyCb
    notify_payload : NotifyPayload
    progress_cb : CheckoutProgressCb
    progress_payload : ProgressCbPayload
    paths : Strarray
    baseline : Tree
    baseline_index : Index
    target_directory : LibC::Char*
    ancestor_label : LibC::Char*
    our_label : LibC::Char*
    their_label : LibC::Char*
    perfdata_cb : CheckoutPerfdataCb
    perfdata_payload : PerfdataCbPayload
  end
end
