module Grits
  struct Credential
    include Mixins::Pointable

    getter :url, :username

    def initialize(@raw : LibGit::Credential*, @url : String, @username : String?); end

    def add_ssh_key(*, username : String, public_key_path : String, private_key_path : String, passphrase : String? = nil)
      LibGit.credential_ssh_key_new(to_unsafe, username, public_key_path, private_key_path, passphrase)
    end

    def add_ssh_key(*, username : String, public_key : String, private_key : String, passphrase : String? = nil)
      LibGit.credential_ssh_key_memory_new(to_unsafe, username, public_key, private_key, passphrase)
    end

    def add_user_pass(*, username : String, password : String)
      LibGit.credential_userpass_plaintext_new(to_unsafe, username, password)
    end

    def from_ssh_agent(*, username : String)
      LibGit.credential_ssh_key_from_agent(to_unsafe, username)
    end
  end
end