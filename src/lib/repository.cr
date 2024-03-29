{% if flag?(:darwin) %}
@[Link("git2.1.3")]
{% else %}
@[Link(ldflags: "-l:libgit2.so.1.3")]
{% end %}
lib LibGit
  type Repository = Void*
  alias RepositoryCb = (Repository*, LibC::Char*, LibC::Int, Void* -> LibC::Int)

  enum RepositoryItemT
    Gitdir
    Workdir
    Commondir
    Index
    Objects
    Refs
    PackedRefs
    Remotes
    Config
    Info
    Hooks
    Logs
    Modules
    Worktrees
    Last
  end

  @[Flags]
  enum RepositoryTypes
    NoSearch
    AcrossFs
    Bare
    NoDotGit
    FromEnv
  end

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

  alias RepositoryFetchheadForeachCb = (LibC::Char*, LibC::Char*, LibGit::Oid*, LibC::UInt, Void* -> LibC::Int)

  fun repository_config_snapshot = git_repository_config_snapshot(out : Config*, repo : Repository) : LibC::Int
  fun repository_item_path = git_repository_item_path(buf : Buf*, repo : Repository, item : RepositoryItemT) : LibC::Int
  fun repository_commondir = git_repository_commondir(repo : Repository) : LibC::Char*
  fun repository_open = git_repository_open(out : Repository*, path : LibC::Char*) : LibC::Int
  fun repository_discover = git_repository_discover(out : Buf*, start_path : LibC::Char*, across_fs : LibC::Int, ceiling_dirs : LibC::Char*) : LibC::Int
  fun repository_open_ext = git_repository_open_ext(out : Repository*, path : LibC::Char*, flags : LibC::UInt, ceiling_dirs : LibC::Char*) : LibC::Int
  fun repository_open_bare = git_repository_open_bare(out : Repository*, bare_path : LibC::Char*) : LibC::Int
  fun repository_free = git_repository_free(repo : Repository)
  fun repository_init = git_repository_init(out : Repository*, path : LibC::Char*, is_bare : LibC::UInt) : LibC::Int
  fun repository_clone = git_repository_clone(out : Repository*, url : LibC::Char*, path : LibC::Char*, clone_options : CloneOptions)

  fun repository_init_options_init = git_repository_init_options_init(opts : RepositoryInitOptions*, version : LibC::UInt) : LibC::Int

  fun repository_init_ext = git_repository_init_ext(out : Repository*, repo_path : LibC::Char*, opts : RepositoryInitOptions*) : LibC::Int
  fun repository_head = git_repository_head(out : Reference*, repo : Repository) : LibC::Int
  fun repository_head_detached = git_repository_head_detached(repo : Repository) : LibC::Int
  fun repository_head_unborn = git_repository_head_unborn(repo : Repository) : LibC::Int
  fun repository_head_for_worktree = git_repository_head_for_worktree(out : Reference*, repo : Repository, name : LibC::Char*) : LibC::Int
  fun repository_head_detached_for_worktree = git_repository_head_detached_for_worktree(repo : Repository, name : LibC::Char*) : LibC::Int
  fun repository_is_worktree = git_repository_is_worktree(repo : Repository) : LibC::Int

  fun repository_is_empty = git_repository_is_empty(repo : Repository) : LibC::Int
  fun repository_path = git_repository_path(repo : Repository) : LibC::Char*
  fun repository_workdir = git_repository_workdir(repo : Repository) : LibC::Char*
  # fun repository_set_workdir = git_repository_set_workdir(repo : Repository, workdir : LibC::Char*, update_gitlink : LibC::Int) : LibC::Int
  fun repository_is_bare = git_repository_is_bare(repo : Repository) : LibC::Int
  fun repository_config = git_repository_config(out : Config*, repo : Repository) : LibC::Int
  # fun repository_config_snapshot = git_repository_config_snapshot(out : X_Config*, repo : Repository) : LibC::Int
  fun repository_odb = git_repository_odb(out : Odb*, repo : Repository) : LibC::Int
  # fun repository_refdb = git_repository_refdb(out : X_Refdb*, repo : Repository) : LibC::Int
  fun repository_index = git_repository_index(out : Index*, repo : Repository) : LibC::Int
  # fun repository_message = git_repository_message(out : Buf*, repo : Repository) : LibC::Int
  # fun repository_message_remove = git_repository_message_remove(repo : Repository) : LibC::Int
  # fun repository_state_cleanup = git_repository_state_cleanup(repo : Repository) : LibC::Int
  fun repository_fetchhead_foreach = git_repository_fetchhead_foreach(repo : Repository, callback : RepositoryFetchheadForeachCb, payload : Void*) : LibC::Int
  # fun repository_mergehead_foreach = git_repository_mergehead_foreach(repo : Repository, callback : RepositoryMergeheadForeachCb, payload : Void*) : LibC::Int
  fun repository_hashfile = git_repository_hashfile(out : Oid*, repo : Repository, path : LibC::Char*, type : OType, as_path : LibC::Char*) : LibC::Int
  fun repository_set_head = git_repository_set_head(repo : Repository, refname : LibC::Char*) : LibC::Int
  # fun repository_set_head_detached = git_repository_set_head_detached(repo : Repository, commitish : Oid*) : LibC::Int
  # fun repository_set_head_detached_from_annotated = git_repository_set_head_detached_from_annotated(repo : Repository, commitish : X_AnnotatedCommit) : LibC::Int
  fun repository_detach_head = git_repository_detach_head(repo : Repository) : LibC::Int
  # fun repository_state = git_repository_state(repo : Repository) : LibC::Int
  # fun repository_set_namespace = git_repository_set_namespace(repo : Repository, nmspace : LibC::Char*) : LibC::Int
  # fun repository_get_namespace = git_repository_get_namespace(repo : Repository) : LibC::Char*
  fun repository_is_shallow = git_repository_is_shallow(repo : Repository) : LibC::Int
  fun repository_ident = git_repository_ident(name : LibC::Char**, email : LibC::Char**, repo : Repository) : LibC::Int
  fun repository_set_ident = git_repository_set_ident(repo : Repository, name : LibC::Char*, email : LibC::Char*) : LibC::Int
end
