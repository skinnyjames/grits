@[Link(ldflags: "-l:libgit2.so.1.3")]
lib LibGit
  GIT_CLONE_OPTIONS_VERSION = 1

  enum CloneLocalT
    Auto
    Local
    NoLocal
    LocalNoLinks
  end

  struct CloneOptions
    version : LibC::UInt
    checkout_opts : CheckoutOptions
    fetch_opts : FetchOptions
    bare : LibC::Int
    local : CloneLocalT
    checkout_branch : LibC::Char*
    repository_cb : RepositoryCb
    repository_cb_payload : Void*
    remote_cb : RemoteCb
    remote_cb_payload : Void*
  end

  fun clone_options_init = git_clone_options_init(opts : CloneOptions*, version : LibC::UInt) : LibC::Int
  fun clone = git_clone(out : Repository*, url : LibC::Char*, path : LibC::Char*, options : CloneOptions*) : LibC::Int
end
