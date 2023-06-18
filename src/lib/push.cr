{% if flag?(:darwin) %}
@[Link("git2.1.3")]
{% else %}
@[Link(ldflags: "-l:libgit2.so.1.3")]
{% end %}
lib LibGit
  struct PushUpdate
    src_refname : LibC::Char*
    dst_refname : LibC::Char*
    src : Oid
    dst : Oid
  end

  alias PushTransferProgressCb = (LibC::UInt, LibC::UInt, LibC::SizeT, Void* -> LibC::Int)
  alias PushUpdateReferenceCb = (LibC::Char*, LibC::Char*, Void* -> LibC::Int)
  alias PushNegotiationCb = (PushUpdate**, LibC::SizeT, Void* -> LibC::Int)
end
