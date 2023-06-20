{% if flag?(:darwin) %}
@[Link("git2.1.3")]
{% else %}
@[Link(ldflags: "-l:libgit2.so.1.3")]
{% end %}
lib LibGit
  type Object = Void*

  enum OType
    Any = -2
    Bad = -1
    Commit = 1
    Tree = 2
    Blob = 3
    Tag = 4
    OfsDelta = 6
    RefDelta = 7
  end

  fun object_lookup_prefix = git_object_lookup_prefix(object_out : Object*, repo : Repository, id : Oid*, len : LibC::SizeT, type : OType) : LibC::Int
  fun object_lookup = git_object_lookup(object : Object*, repo : Repository, id : Oid*, type : OType) : LibC::Int
  fun object_id = git_object_id(obj : Object) : Oid*
  fun object_short_id = git_object_short_id(out : Buf*, obj : Object) : LibC::Int
  fun object_type = git_object_type(obj : Object) : OType
  fun object_owner = git_object_owner(obj : Object) : Repository
  fun object_free = git_object_free(obj : Object)
end
