@[Link(ldflags: "-l:libgit2.so.1.3")]
lib LibGit
  type PackBuilder = Void*

  enum PackBuilderStageT
    AddingObjects = 0
    Deltafication = 1
  end
  
  fun packbuilder_new = git_packbuilder_new(out : PackBuilder*, repo : Repository) : LibC::Int
  fun packbuilder_free = git_packbuilder_free(pb : PackBuilder) : Void
  fun packbuilder_set_threads = git_packbuilder_set_threads(pb : PackBuilder, n : LibC::UInt)
  fun packbuilder_insert = git_packbuilder_insert(pb : PackBuilder, id : Oid*, name : LibC::Char*) : LibC::Int
  fun packbuilder_insert_tree = git_packbuilder_insert_tree(pb : PackBuilder, id : Oid*) : LibC::Int
  fun packbuilder_insert_commit = git_packbuilder_insert_commit(pb : PackBuilder, id : Oid*) : LibC::Int
  fun packbuilder_insert_walk = git_packbuilder_insert_walk(pb : PackBuilder, walk : Revwalk) : LibC::Int
  fun packbuilder_insert_recur = git_packbuilder_insert_recur(pb : PackBuilder, id : Oid*, name : LibC::Char*) : LibC::Int
  fun packbuilder_write_but = git_packbuilder_write_buf(buf : Buf*, pb : PackBuilder) : LibC::Int
  fun packbuilder_write = git_packbuilder_write(pb : PackBuilder, path : LibC::Char*, mode : LibC::UInt, progress_cb : IndexerProgressCb, progress_cb_payload : Void*) : LibC::Int
  # something 
  fun packbuilder_hash = git_packbuilder_hash(pb : PackBuilder) : Oid*
  fun packbuilder_name = git_packbuilder_name(pb : PackBuilder) : LibC::Char*
  
  alias PackBuilderForeachCb = (Buf*, LibC::SizeT, Void* -> LibC::Int)

  fun packbuilder_foreach = git_packbuilder_foreach(pb : PackBuilder, cb : PackBuilderForeachCb, payload : Void*) : LibC::Int
  fun packbuilder_object_count = git_packbuilder_object_count(pb : PackBuilder) : LibC::SizeT
  fun packbuilder_written = git_packbuilder_written(pb : PackBuilder) : LibC::SizeT
  
  alias PackbuilderProgress = (LibC::Int, UInt32, UInt32, Void* -> LibC::Int)

  fun packbuilder_set_callbacks = git_packbuilder_set_callbacks(pb : PackBuilder, progress_cb : PackbuilderProgress, progress_cb_payload : Void*) : LibC::Int
end
