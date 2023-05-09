@[Link(ldflags: "-l:libgit2.so.1.3")]
lib LibGit
  alias CheckoutProgressCb = (LibC::Char*, LibC::SizeT, LibC::SizeT, Void* -> Void)
  alias CheckoutPerfdataCb = (CheckoutPerfdata*, Void* -> Void)
  alias CheckoutNotifyCb = (CheckoutNotifyT, LibC::Char*, DiffFile*, DiffFile*, DiffFile*, Void* -> LibC::Int)

  enum CheckoutNotifyT
    None
    Conflict
    Diry
    Updated
    Untracked
    Ignared
    All
  end

  struct CheckoutPerfdata
    mkdir_calls : LibC::SizeT
    stat_calls : LibC::SizeT
    chmod_calls : LibC::SizeT
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

  fun checkout_tree = git_checkout_tree(repo : Repository, treeish : Object, options : CheckoutOptions*) : LibC::Int
  fun checkout_head = git_checkout_head(repository : Repository, options : CheckoutOptions*) : LibC::Int
  fun checkout_options_init = git_checkout_options_init(options : CheckoutOptions*, version : LibC::UInt) : LibC::Int
end
