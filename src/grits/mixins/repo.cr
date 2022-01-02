module Grits
  module Mixins
    module Repo
      def bare?
        LibGit.repository_is_bare(@raw) == 1
      end

      def empty?
        LibGit.repository_is_empty(@raw) == 1
      end

      def workdir
        working_dir = LibGit.repository_workdir(@raw)
        raise Error::Generic.new("Cannot get the working directory, is the repository bare?") if working_dir.null?
        String.new(working_dir)
      end

      def path
        String.new LibGit.repository_path(@raw)
      end

      def head
        head? || raise Error::Generic.new("Reference is null, is the repository bare?")
      end

      def head?
        Error.giterr LibGit.repository_head(out ref, @raw), "Cannot fetch repository head"
        return Reference.new(ref) unless ref.null?
      end

      def head_unborn?
        LibGit.repository_head_unborn(@raw) == 1
      end

      def head_detached?
        LibGit.repository_head_detached(@raw) == 1
      end

      def detach_head
        Error.giterr LibGit.repository_detach_head(@raw)
      end

      def shallow? : Bool
        LibGit.repository_is_shallow(@raw) == 1
      end

      def lookup_commit(oid_ptr : Pointer(LibGit::Oid))
        Error.giterr LibGit.commit_lookup(out commit, @raw, oid_ptr), "Cannot load commit"
        Commit.new(commit)
      end

      def lookup_commit(oid : Oid)
        lookup_commit oid.pointer
      end

      def lookup_commit(sha : String)
        lookup_commit Oid.from_sha(sha)
      end
    end
  end
end
