{% if flag?(:windows) %}
  @[Link(ldflags: "-L#{__DIR__}/../../vendor/lib -lgit2")]
{% else %}
  @[Link(ldflags: "-L#{__DIR__}/../../vendor/lib -Wl,-rpath,#{__DIR__}/../../vendor/lib -lgit2")]
{% end %}
lib LibGit
  type Transport = Void*

  alias TransportCb = (Transport*, Remote, Void* -> LibC::Int)
  alias TransportMessageCb = (LibC::Char*, LibC::Int, Void* -> LibC::Int)
  alias TransportCertificateCheckCb = (Credential*, LibC::Char*, LibC::Char*, LibC::UInt, Void* -> LibC::Int)
end
