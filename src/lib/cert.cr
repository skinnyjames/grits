{% if flag?(:darwin) %}
@[Link("git2.1.3")]
{% else %}
@[Link(ldflags: "-l:libgit2.so.1.3")]
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
