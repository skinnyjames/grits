{% if flag?(:darwin) %}
@[Link("git2.1.3")]
{% else %}
@[Link(ldflags: "-l:libgit2.so.1.3")]
{% end %}
lib LibGit
  enum FetchPruneT
    Unspecified
    Prune
    NoPrune
  end

  struct FetchOptions
    version : LibC::Int
    callbacks : RemoteCallbacks
    prune : FetchPruneT
    update_fetchhead : LibC::Int
    download_tags : RemoteAutotagOptionT
    proxy_opts : ProxyOptions
    custom_headers : Strarray
  end

  fun fetch_options_init = git_fetch_options_init(options : FetchOptions*, version : LibC::UInt) : LibC::Int
end
