{% if flag?(:darwin) %}
@[Link("git2.1.3")]
{% else %}
@[Link(ldflags: "-l:libgit2.so.1.3")]
{% end %}
lib LibGit
  type Index = Void*

  enum IndexAddOptionT
    Default = 0
    Force = (1 << 0)
    DisablePathspecMatch = (1 << 1)
    CheckPathspec = (1 << 2)
  end

  struct IndexTime
    seconds : Int32
    nanoseconds : UInt32
  end

  struct IndexEntry
    ctime : IndexTime
    mtime : IndexTime
    dev : UInt32
    ino : UInt32
    mode : UInt32
    uid : UInt32
    gid : UInt32
    file_size : UInt32
    id : LibGit::Oid
    flags : UInt16
    flags_extends : UInt16
    path : LibC::Char*
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

  alias IndexMatchedPathCb = (LibC::Char*, LibC::Char*, Void* -> LibC::Int)
  alias IndexerProgressCb = (IndexerProgress*, Void* -> LibC::Int)

  # operations
  fun index_add = git_index_add(index: Index, entry : IndexEntry) : LibC::Int
  fun index_add_all = git_index_add_all(index : Index, pathspec : LibGit::Strarray*, flags : LibC::UInt, callback : IndexMatchedPathCb, payload : Void*) : LibC::Int
  fun index_add_bypath = git_index_add_bypath(index : Index, path : LibC::Char*) : LibC::Int
  fun index_write = git_index_write(index : Index) : LibC::Int
  fun index_clear = git_index_clear(index : Index) : LibC::Int
  fun index_has_conflicts = git_index_has_conflicts(index : Index) : LibC::Int

  # lookups
  fun index_read_tree = git_index_read_tree(index : Index, tree : Tree*) : LibC::Int
  fun index_write_tree = git_index_write_tree(out : Oid*, index : Index) : LibC::Int

  # free
  fun index_free = git_index_free(index : Index) : Void
end
