@[Link(ldflags: "-l:libgit2.so.1.3")]
lib LibGit
  type Credential = Void*
  alias CredentialsAcquireCb = (Credential*, LibC::Char*, LibC::Char*, LibC::UInt, Void* -> LibC::Int)

  fun credential_ssh_key_new = git_credential_ssh_key_new(out : Credential*, username : LibC::Char*, publickey : LibC::Char*, privatekey : LibC::Char*, passphrase : LibC::Char*) : LibC::Int
  fun credential_ssh_key_memory_new = git_credential_ssh_key_memory_new(out : Credential*, username : LibC::Char*, publickey : LibC::Char*, privatekey : LibC::Char*, passphrase : LibC::Char*) : LibC::Int
  fun credential_ssh_key_from_agent = git_credential_ssh_key_from_agent(out : Credential*, username : LibC::Char*) : LibC::Int
  fun credential_userpass_plaintext_new = git_credential_userpass_plaintext_new(out : Credential*, username : LibC::Char*, password : LibC::Char*) : LibC::Int
end
