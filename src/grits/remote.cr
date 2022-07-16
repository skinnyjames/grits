module Grits
  class Remote
    include Mixins::Pointable

    def self.create(repo : Repo, name : String, url : String)
      Error.giterr LibGit.remote_create(out remote, repo, name, url), "Couldn't create remote #{name} at #{url}"
      new(remote)
    end

    def initialize(@raw : LibGit::Remote)
    end

    def name
      String.new(LibGit.remote_name(to_unsafe))
    end

    def url
      String.new(LibGit.remote_url(to_unsafe))
    end
  end
end