module Grits
  class Branch
    def self.create(name : String, target : Commit, force : Bool = false)
      Error.giterr(LibGit.branch_create(out reference, target.repo, name, target, force ? 1 : 0), "Could not checkout branch #{name}")

      new(target.repo, reference)
    end

    def self.create(name : String, target : Repo, *, commit_ref : String = "HEAD", force : Bool = false)
      branch = nil
      target.commit_at(commit_ref) do |commit|
        Error.giterr(LibGit.branch_create(out reference, target, name, commit, force ? 1 : 0), "Could not checkout branch #{name}")
        branch = new(target, reference)
      end

      branch.not_nil!
    end

    getter :repo

    def initialize(@repo : Repo, @ref : LibGit::Reference); end

    def ref
      Reference.new(repo, @ref)
    end

    def id : Oid
      ref.id
    end

    def checked_out? : Bool
      stat = LibGit.branch_is_checked_out(@ref)
      Error.giterr(stat, "Could not confirm checkout") unless [0,1].includes?(stat) && !stat.nil?

      !stat.zero?
    end

    def checkout(options : CheckoutOptions = CheckoutOptions.default) : Nil
      repo.checkout_tree(id.object(repo), options)
      repo.set_head(ref.name)
    end
  end
end
