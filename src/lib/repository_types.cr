@[Link("git2")]
lib LibGit
  GIT_CLONE_OPTIONS_VERSION = 1
  REMOTE_CALLBACKS_VERSION = 1

  alias GenericPayload = Void*

  type Credential = Void*
  type Certificate = Void*
  type Transport = Void*

  struct GitCert
    cert_type : GitCertT
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

  enum GitCertT
    NONE
    X509
    HOSTKEY_LIBSSH2
    STRARRAY
  end

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

  enum RemoteCompletionT
    Download
    Indexing
    Error
  end

  enum FetchPruneT
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

  alias RepositoryCb = (Repository*, LibC::Char*, LibC::Int, Void* -> LibC::Int)
  alias RemoteCb = (Remote*, Repository, LibC::Char*, LibC::Char*, Void* -> LibC::Int)
  alias RemoteReadyCb = (Remote, LibC::Int, Void* -> LibC::Int)
  alias CheckoutNotifyCb = (CheckoutNotify, LibC::Char*, DiffFile*, DiffFile*, DiffFile*, Void* -> LibC::Int)
  alias CheckoutProgressCb = (LibC::Char*, LibC::SizeT, LibC::SizeT, Void* -> Void)
  alias CheckoutPerfdataCb = (CheckoutPerfdata*, Void* -> Void)
  alias CredentialsAcquireCb = (Credential*, LibC::Char*, LibC::Char*, LibC::UInt, Void* -> LibC::Int)
  alias TransportCb = (Transport*, Remote, Void* -> LibC::Int)
  alias TransportMessageCb = (LibC::Char*, LibC::Int, Void* -> LibC::Int)
  alias TransportCertificateCheckCb = (Credential*, LibC::Char*, LibC::Char*, LibC::UInt, Void* -> LibC::Int)
  alias IndexerProgressCb = (IndexerProgress*, Void* -> LibC::Int)
  alias PushTransferProgressCb = (LibC::UInt, LibC::UInt, LibC::SizeT, Void* -> LibC::Int)
  alias PushUpdateReferenceCb = (LibC::Char*, LibC::Char*, Void* -> LibC::Int)
  alias PushNegotiationCb = (PushUpdate**, LibC::SizeT, Void* -> LibC::Int)
  alias UrlResolveCb = (Buf*, LibC::Char*, LibC::Int, Void* -> LibC::Int)

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
    sideband_progress : (LibC::Char*, LibC::Int, Void* -> LibC::Int) # todo
    completion :  (RemoteCompletionT, Void* -> LibC::Int) #done
    credentials : (Credential*, LibC::Char*, LibC::Char*, LibC::UInt, Void* -> LibC::Int) #done
    certificate_check : (GitCert*, LibC::Int, LibC::Char*, Void* -> LibC::Int) #done
    transfer_progress : (IndexerProgress*, Void* -> LibC::Int) #done
    update_tips : (LibC::Char*, Oid*, Oid*,  Void* -> LibC::Int) # done
    pack_progress : (LibC::Int, Uint32T, Uint32T, Void* -> LibC::Int) #done
    push_transfer_progress :  (LibC::UInt, LibC::UInt, LibC::SizeT, Void* -> LibC::Int) #done
    push_update_reference : (LibC::Char*, LibC::Char*, Void* -> LibC::Int) #done
    push_negotiation : (PushUpdate**, LibC::SizeT, Void* -> LibC::Int) #done
    transport : (Transport*, Remote, Void* -> LibC::Int) #revisit but done
    payload : Void*
    resolve_url : (Buf*, LibC::Char*, LibC::Int, Void* -> LibC::Int) #done
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
    repository_cb_payload : Void*
    remote_cb : RemoteCb
    remote_cb_payload : Void*
  end

  struct CheckoutPerfdata
    mkdir_calls : LibC::SizeT
    stat_calls : LibC::SizeT
    chmod_calls : LibC::SizeT
  end

  struct FetchOptions
    version : LibC::Int
    callbacks : RemoteCallbacks
    prune : FetchPruneT
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
    notify_payload : Void*
    progress_cb : CheckoutProgressCb
    progress_payload : Void*
    paths : Strarray
    baseline : Tree
    baseline_index : Index
    target_directory : LibC::Char*
    ancestor_label : LibC::Char*
    our_label : LibC::Char*
    their_label : LibC::Char*
    perfdata_cb : CheckoutPerfdataCb
    perfdata_payload : Void*
  end

  fun fetch_options_init = git_fetch_options_init(options : FetchOptions*, version : LibC::UInt) : LibC::Int
  fun credential_ssh_key_new = git_credential_ssh_key_new(out : Credential*, username : LibC::Char*, publickey : LibC::Char*, privatekey : LibC::Char*, passphrase : LibC::Char*) : LibC::Int
  fun credential_ssh_key_memory_new = git_credential_ssh_key_memory_new(out : Credential*, username : LibC::Char*, publickey : LibC::Char*, privatekey : LibC::Char*, passphrase : LibC::Char*) : LibC::Int
  fun credential_ssh_key_from_agent = git_credential_ssh_key_from_agent(out : Credential*, username : LibC::Char*) : LibC::Int
  fun credential_userpass_plaintext_new = git_credential_userpass_plaintext_new(out : Credential*, username : LibC::Char*, password : LibC::Char*) : LibC::Int
end
