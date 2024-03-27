{% if flag?(:windows) %}
  @[Link(ldflags: "-L#{__DIR__}/../../vendor/lib -lgit2")]
{% else %}
  @[Link(ldflags: "-L#{__DIR__}/../../vendor/lib -Wl,-rpath,#{__DIR__}/../../vendor/lib -lgit2")]
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
