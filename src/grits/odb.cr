module Grits
  class Odb
    include Mixins::Pointable

    def self.from_repo(repo : Repo)
      Error.giterr LibGit.repository_odb(out odb, repo.to_unsafe), "Can't load object database"
      new(odb)
    end

    def initialize(@raw : LibGit::Odb); end

    def free
      LibGit.odb_free(to_unsafe)
    end
  end
end