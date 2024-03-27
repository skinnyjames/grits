{% if flag?(:windows) %}
  @[Link(ldflags: "-L#{__DIR__}/../../vendor/lib -lgit2")]
{% else %}
  @[Link(ldflags: "-L#{__DIR__}/../../vendor/lib -Wl,-rpath,#{__DIR__}/../../vendor/lib -lgit2")]
{% end %}
lib LibGit
  struct ProxyOptions
    version : LibC::UInt
    type : ProxyT
    url : LibC::Char*
    credentials : (Credential*, LibC::Char*, LibC::Char*, LibC::UInt, Void* -> LibC::Int)
    certificate_check : (GitCert*, LibC::Int, LibC::Char*, Void* -> LibC::Int)
    payload : Void*
  end

  enum ProxyT
    None
    Auto
    Specified
  end
end
