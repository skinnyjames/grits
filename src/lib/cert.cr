@[Link("git2")]
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
