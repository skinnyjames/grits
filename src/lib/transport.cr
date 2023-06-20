{% if flag?(:darwin) %}
@[Link("git2.1.3")]
{% else %}
@[Link(ldflags: "-l:libgit2.so.1.3")]
{% end %}
lib LibGit
  type Transport = Void*

  alias TransportCb = (Transport*, Remote, Void* -> LibC::Int)
  alias TransportMessageCb = (LibC::Char*, LibC::Int, Void* -> LibC::Int)
  alias TransportCertificateCheckCb = (Credential*, LibC::Char*, LibC::Char*, LibC::UInt, Void* -> LibC::Int)
end
