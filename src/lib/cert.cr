{% if flag?(:windows) %}
  @[Link(ldflags: "-L#{__DIR__}/../../vendor/lib -lgit2")]
{% else %}
  @[Link(ldflags: "-L#{__DIR__}/../../vendor/lib -Wl,-rpath,#{__DIR__}/../../vendor/lib -lgit2")]
{% end %}
lib LibGit  
  type Certificate = Void*

  struct GitCert
    cert_type : GitCertT
  end

  enum GitCertT
    NONE
    X509
    HOSTKEY_LIBSSH2
    STRARRAY
  end
end
