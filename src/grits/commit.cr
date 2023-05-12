module Grits
  struct Signature
    include Mixins::Pointable

    def self.make(name : String, email : String, time : Time)
      stamp = LibGit::Time.new(time: time.to_unix, offset: time.offset)
      Error.giterr LibGit.signature_new(out signature_ptr, name, email, time.to_unix, time.offset), "Cannot create signature"
      new(signature_ptr)
    end

    def self.from_tuple(tuple : Commit::SignatureTuple)
      make(tuple[:name], tuple[:email], tuple[:time])
    end

    def self.now(name : String, email : String)
      Error.giterr LibGit.signature_now(out signature, name, email), "Cannot Create Signature"
      new(signature)
    end

    def initialize(@raw : Pointer(LibGit::Signature)); end

    def name
      String.new(to_unsafe.value.name)
    end

    def email
      String.new(to_unsafe.value.email)
    end

    def time
      Time.unix to_unsafe.value.when.time
    end

    def free
      LibGit.signature_free(to_unsafe)
    end
  end


  struct Commit
    include Mixins::Pointable

    getter :repo

    alias SignatureTuple = { name: String, email: String, time: Time }

    def self.create(
      repo : Grits::Repo,
      *,
      message : String,
      author : SignatureTuple,
      committer : SignatureTuple,
      parents : Array(Commit),
      tree : Grits::Tree,
      encoding : String = "UTF-8",
      update_ref : String | Reference,
      &
    )
      author_signature = Signature.from_tuple(author)
      committer_signature = author == committer ? author_signature : Signature.from_tuple(committer)

      parent_size = parents.size.to_u64
      parent_refs = parents.map(&.to_unsafe)

      LibGit.commit_create(out commit_id, repo.to_unsafe, update_ref, author_signature.to_unsafe, committer_signature.to_unsafe, encoding, message, tree.to_unsafe, parent_size, parent_refs)
      
      oid = Oid.new(commit_id)
      commit = lookup(repo, oid)
      author_signature.free
      committer_signature.free unless author == committer

      begin
        yield(commit)
      ensure
        commit.free    
      end
    end

    def self.lookup(repo : Repo, id : Oid)
      Error.giterr LibGit.commit_lookup(out commit, repo.to_unsafe, id.to_unsafe_ptr), "Cannot lookup commit"
      new(commit, repo)
    end

    def initialize(@raw : LibGit::Commit, @repo : Grits::Repo); end

    def message
      String.new LibGit.commit_message(to_unsafe)
    end

    def author
      Signature.new(LibGit.commit_author(to_unsafe))
    end

    def committer
      Signature.new(LibGit.commit_committer(to_unsafe))
    end

    def tree(& : Grits::Tree ->)
      tree = Tree.from_commit(self)
      begin
        yield(tree)
      ensure
        tree.free
      end
    end

    def tree_id
      Oid.new(LibGit.commit_tree_id(to_unsafe).value)
    end

    def sha
      id.to_s
    end

    def id
      oid = LibGit.commit_id(to_unsafe)
      Oid.new(oid.value)
    end

    def free
      LibGit.commit_free(to_unsafe)
    end
  end
end
