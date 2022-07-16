module Grits
  module Mixins
    module Repo
      def bare?
        LibGit.repository_is_bare(to_unsafe) == 1
      end

      def empty?
        LibGit.repository_is_empty(to_unsafe) == 1
      end

      def workdir
        working_dir = LibGit.repository_workdir(to_unsafe)
        raise Error::Generic.new("Cannot get the working directory, is the repository bare?") if working_dir.null?
        String.new(working_dir)
      end

      def path
        String.new LibGit.repository_path(to_unsafe)
      end

      def head
        head? || raise Error::Generic.new("Reference is null, is the repository bare?")
      end

      def head?
        Error.giterr LibGit.repository_head(out ref, to_unsafe), "Cannot fetch repository head"
        return Reference.new(ref) unless ref.null?
      end

      def head_unborn?
        LibGit.repository_head_unborn(to_unsafe) == 1
      end

      def head_detached?
        LibGit.repository_head_detached(to_unsafe) == 1
      end

      def detach_head
        Error.giterr LibGit.repository_detach_head(to_unsafe)
      end

      def shallow? : Bool
        LibGit.repository_is_shallow(to_unsafe) == 1
      end

      def remote(name : String)
        Error.giterr LibGit.remote_lookup(out remote, to_unsafe, name), "Cannot fetch remote #{name}"
        Remote.new(remote)
      end

      def lookup_commit(oid : Oid)
        lookup_commit oid.to_unsafe
      end

      def lookup_commit(sha : String)
        lookup_commit Oid.from_sha(sha)
      end

      def lookup_tree(oid : Oid)
        Error.giterr LibGit.tree_lookup(out tree, to_unsafe, oid.to_unsafe), "couldn't lookup tree"
        Tree.new(tree)
      end

      def lookup_tree(sha : String)
        lookup_tree Oid.from_sha(string)
      end

      def last_commit
        Error.giterr LibGit.reference_name_to_id(out oid, to_unsafe, "HEAD"), "couldn't reference id"
        lookup_commit Oid.new(pointerof(oid))
      end

      protected def lookup_commit(oid_ptr : Pointer(LibGit::Oid))
        Error.giterr LibGit.commit_lookup(out commit, to_unsafe, oid_ptr), "Cannot load commit"
        Commit.new(commit)
      end
    end
  end
end
