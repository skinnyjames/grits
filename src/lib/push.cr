{% if flag?(:windows) %}
  @[Link(ldflags: "-L#{__DIR__}/../../vendor/lib -lgit2")]
{% else %}
  @[Link(ldflags: "-L#{__DIR__}/../../vendor/lib -Wl,-rpath,#{__DIR__}/../../vendor/lib -lgit2")]
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
