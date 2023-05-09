@[Link(ldflags: "-l:libgit2.so.1.3")]
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
