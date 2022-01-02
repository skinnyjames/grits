module Grits
  struct Signature
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
      String.new(@raw.value.name)
    end

    def email
      String.new(@raw.value.email)
    end

    def time
      Time.unix @raw.value.when.time
    end

    def raw
      @raw
    end

    def free
      LibGit.signature_free(@raw)
    end
  end


  class Commit
    include Mixins::Pointable

    alias SignatureTuple = { name: String, email: String, time: Time }

    def self.create(repo : Grits::Repo, **args, &block)
      commit = create(repo, **args)
      begin
        yield commit
      ensure
        commit.free
      end
    end

    def self.create(
      repo : Grits::Repo,
      *,
      message : String,
      author : SignatureTuple,
      committer : SignatureTuple,
      parents : Array(String),
      tree : Grits::Tree,
      encoding : String = "UTF-8",
      update_ref : String | Reference
    )

      author_signature = Signature.from_tuple(author)
      committer_signature = author == committer ? author_signature : Signature.from_tuple(committer)

      parent_size = parents.size.to_u64
      parent_refs = parents.map do |id|
        repo.lookup_commit(id).raw
      end

      LibGit.commit_create(out commit_id, repo.raw, update_ref, author_signature.raw, committer_signature.raw, encoding, message, tree.raw, parent_size, parent_refs)
      commit = repo.lookup_commit(pointerof(commit_id))

      author_signature.free
      committer_signature.free unless author == committer

      commit
    end

    def initialize(@raw : LibGit::Commit); end

    def message
      String.new LibGit.commit_message(@raw)
    end

    def author
      Signature.new(LibGit.commit_author(@raw))
    end

    def committer
      Signature.new(LibGit.commit_committer(@raw))
    end

    def free
      LibGit.commit_free(@raw)
    end
  end
end
