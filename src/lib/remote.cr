@[Link(ldflags: "-l:libgit2.so.1.3")]
lib LibGit
  REMOTE_CALLBACKS_VERSION = 1

  type Remote = Void*

  alias RemoteCb = (Remote*, Repository, LibC::Char*, LibC::Char*, Void* -> LibC::Int)
  alias RemoteReadyCb = (Remote, LibC::Int, Void* -> LibC::Int)
  alias UrlResolveCb = (Buf*, LibC::Char*, LibC::Int, Void* -> LibC::Int)

  enum RemoteAutoTagOptionT
    DownloadTagsUnspecified
    DownloadTagsAuto
    DownloadTagsNone
    DownloadTagsAll
  end

  enum RemoteAutotagOptionT
    Unspecified
    Auto
    None
    All
  end

  enum RemoteCompletionT
    Download
    Indexing
    Error
  end

  enum RemoteRedirectT
    None = (1 << 0)
    Initial = (1 << 1)
    All = (1 << 2)
  end

  struct RemoteConnectOptions
    version : LibC::UInt
    callbacks : RemoteCallbacks
    proxy_opts : ProxyOptions
    follow_redirects : RemoteRedirectT
    custom_headers : Strarray
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
    push_negotiation : (PushUpdate**, LibC::SizeT, Void* -> LibC::Int) #done (revisit with PushUpdate**)
    transport : (Transport*, Remote, Void* -> LibC::Int) #revisit but done
    remote_ready : (Remote, LibC::Int, Void* -> LibC::Int) # done
    payload : Void*
    resolve_url : (Buf*, LibC::Char*, LibC::Int, Void* -> LibC::Int) #done
  end

  fun remote_connect_options_init = git_remote_connect_options_init(opts : RemoteConnectOptions*, version : LibC::UInt) : LibC::Int
  fun remote_update_tips = git_remote_update_tips(remote : Remote, callbacks : RemoteCallbacks, update_fetchhead : LibC::Int, download_tags : RemoteAutoTagOptionT, reflog_message : LibC::Char*) : LibC::Int
  fun remote_create = git_remote_create(out : Remote*, repo : Repository, name : LibC::Char*, url : LibC::Char*) : LibC::Int
  fun remote_create_with_fetchspec = git_remote_create_with_fetchspec(out : Remote*, repo : Repository, name : LibC::Char*, url : LibC::Char*, fetch : LibC::Char*) : LibC::Int
  fun remote_create_anonymous = git_remote_create_anonymous(out : Remote*, repo : Repository, url : LibC::Char*) : LibC::Int
  fun remote_lookup = git_remote_lookup(out : Remote*, repo : Repository, name : LibC::Char*) : LibC::Int
  fun remote_dup = git_remote_dup(dest : Remote*, source : Remote) : LibC::Int
  fun remote_owner = git_remote_owner(remote : Remote) : Repository
  fun remote_name = git_remote_name(remote : Remote) : LibC::Char*
  fun remote_url = git_remote_url(remote : Remote) : LibC::Char*
  fun remote_pushurl = git_remote_pushurl(remote : Remote) : LibC::Char*
  fun remote_set_url = git_remote_set_url(repo : Repository, remote : LibC::Char*, url : LibC::Char*) : LibC::Int
  fun remote_set_pushurl = git_remote_set_pushurl(repo : Repository, remote : LibC::Char*, url : LibC::Char*) : LibC::Int
  fun remote_add_fetch = git_remote_add_fetch(repo : Repository, remote : LibC::Char*, refspec : LibC::Char*) : LibC::Int
  fun remote_get_fetch_refspecs = git_remote_get_fetch_refspecs(array : Strarray*, remote : Remote) : LibC::Int
  fun remote_add_push = git_remote_add_push(repo : Repository, remote : LibC::Char*, refspec : LibC::Char*) : LibC::Int
  fun remote_get_push_refspecs = git_remote_get_push_refspecs(array : Strarray*, remote : Remote) : LibC::Int
  fun remote_refspec_count = git_remote_refspec_count(remote : Remote) : LibC::SizeT
  fun remote_ls = git_remote_ls(out : RemoteHead***, size : LibC::SizeT*, remote : Remote) : LibC::Int
  fun remote_connected = git_remote_connected(remote : Remote) : LibC::Int
  fun remote_stop = git_remote_stop(remote : Remote)
  fun remote_disconnect = git_remote_disconnect(remote : Remote)
  fun remote_free = git_remote_free(remote : Remote)
  fun remote_list = git_remote_list(out : Strarray*, repo : Repository) : LibC::Int
  fun remote_fetch = git_remote_fetch(out : Remote, refspecs : Strarray*, opts : FetchOptions*, reflog_message : LibC::Char*) : LibC::Int
  fun remote_init_callbacks = git_remote_init_callbacks(opts : RemoteCallbacks*, version : LibC::UInt) : LibC::Int
end
