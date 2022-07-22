@[Link("git2")]
lib LibGit
  DIFF_OPTIONS_VERSION = 1

  type Diff = Void*

  alias DiffNotifyCb = (Diff, DiffDelta*, LibC::Char*, Void* -> LibC::Int)
  alias DiffProgressCb = (Diff, LibC::Char*, LibC::Char*, Void* -> LibC::Int)

  struct DiffOptions
    version : LibC::UInt
    flags : Uint32T
    ignore_submodules : SubmoduleIgnoreT
    pathspec : Strarray
    notify_cb : DiffNotifyCb
    progress_cb : DiffProgressCb
    payload : Void*
    context_lines : Uint32T
    interhunk_lines : Uint32T
    id_abbrev : Uint16T
    max_size : OffT
    old_prefix : LibC::Char*
    new_prefix : LibC::Char*
  end

  enum DeltaT
    Unmodified =  0
    Added      =  1
    Deleted    =  2
    Modified   =  3
    Renamed    =  4
    Copied     =  5
    Ignored    =  6
    Untracked  =  7
    Typechange =  8
    Unreadable =  9
    Conflicted = 10
  end

  struct DiffDelta
    status : DeltaT
    flags : Uint32T
    similarity : Uint16T
    nfiles : Uint16T
    old_file : DiffFile
    new_file : DiffFile
  end

  struct DiffFile
    id : Oid
    path : LibC::Char*
    size : OffT
    flags : Uint32T
    mode : Uint16T
    id_abbrev : Uint16T
  end

  alias DiffFileCb = (DiffDelta*, LibC::Float, Void* -> LibC::Int)

  struct DiffHunk
    old_start : LibC::Int
    old_lines : LibC::Int
    new_start : LibC::Int
    new_lines : LibC::Int
    header_len : LibC::SizeT
    header : LibC::Char[128]
  end

  alias DiffHunkCb = (DiffDelta*, DiffHunk*, Void* -> LibC::Int)

  DIFF_LINE_CONTEXT  = ' '
  DIFF_LINE_ADDITION = '+'
  DIFF_LINE_DELETION = '-'

  struct DiffLine
    origin : LibC::Char
    old_lineno : LibC::Int
    new_lineno : LibC::Int
    num_lines : LibC::Int
    content_len : LibC::SizeT
    content_offset : OffT
    content : LibC::Char*
  end

  alias DiffLineCb = (DiffDelta*, DiffHunk*, DiffLine*, Void* -> LibC::Int)

  struct DiffBinaryFile
    type : DiffBinaryT
    data : LibC::Char*
    datalen : LibC::SizeT
    inflatedlen : LibC::SizeT
  end

  enum DiffBinaryT
    DiffBinaryNone    = 0
    DiffBinaryLiteral = 1
    DiffBinaryDelta   = 2
  end

  struct DiffBinary
    contains_data : LibC::UInt
    old_file : DiffBinaryFile
    new_file : DiffBinaryFile
  end

  alias DiffBinaryCb = (DiffDelta*, DiffBinary*, Void* -> LibC::Int)

  struct DiffFindOptions
    version : LibC::UInt
    flags : Uint32T
    rename_threshold : Uint16T
    rename_from_rewrite_threshold : Uint16T
    copy_threshold : Uint16T
    break_rewrite_threshold : Uint16T
    rename_limit : LibC::SizeT
    metric : DiffSimilarityMetric*
  end

  struct DiffSimilarityMetric
    file_signature : (Void**, DiffFile*, LibC::Char*, Void* -> LibC::Int)
    buffer_signature : (Void**, DiffFile*, LibC::Char*, LibC::SizeT, Void* -> LibC::Int)
    free_signature : (Void*, Void* -> Void)
    similarity : (LibC::Int*, Void*, Void*, Void* -> LibC::Int)
    payload : Void*
  end

  fun diff_free = git_diff_free(diff : Diff)
  fun diff_tree_to_tree = git_diff_tree_to_tree(diff : Diff*, repo : Repository, old_tree : Tree, new_tree : Tree, opts : DiffOptions*) : LibC::Int
  fun diff_tree_to_workdir = git_diff_tree_to_workdir(diff : Diff*, repo : Repository, old_tree : Tree, opts : DiffOptions*) : LibC::Int
  fun diff_tree_to_workdir_with_index = git_diff_tree_to_workdir_with_index(diff : Diff*, repo : Repository, old_tree : Tree, opts : DiffOptions*) : LibC::Int
  fun diff_merge = git_diff_merge(onto : Diff, from : Diff) : LibC::Int
  fun diff_find_similar = git_diff_find_similar(diff : Diff, options : DiffFindOptions*) : LibC::Int
  fun diff_num_deltas = git_diff_num_deltas(diff : Diff) : LibC::SizeT
  fun diff_num_deltas_of_type = git_diff_num_deltas_of_type(diff : Diff, type : DeltaT) : LibC::SizeT
  fun diff_get_delta = git_diff_get_delta(diff : Diff, idx : LibC::SizeT) : DiffDelta*
  fun diff_is_sorted_icase = git_diff_is_sorted_icase(diff : Diff) : LibC::Int
  fun diff_foreach = git_diff_foreach(diff : Diff, file_cb : DiffFileCb, binary_cb : DiffBinaryCb, hunk_cb : DiffHunkCb, line_cb : DiffLineCb, payload : Void*) : LibC::Int
  fun diff_init_options = git_diff_init_options(opts : DiffOptions*, version : LibC::UInt) : LibC::Int
end
