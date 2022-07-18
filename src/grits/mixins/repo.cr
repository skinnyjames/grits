module Grits
  module Mixins
    module Repo

      alias EachFetchHeadCb = (String, String, Oid, Bool -> Bool?)

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

      def commondir
        String.new(LibGit.repository_commondir(to_unsafe))
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

      def namespace : String?
        val = LibGit.repository_get_namespace(to_unsafe)
        val.null? ? nil : String.new(val)
      end

      def discover(start : String, across_fs : Bool = false, cieling_dirs : String = "") : String
        across = across_fs ? 1 : 0
        buffer = Buffer.create
        Error.giterr LibGit.repository_discover(buffer.to_unsafe_ptr, start, across, cieling_dirs), "Cannot discover repo"
        buffer.to_s
      ensure
        buffer.free if buffer
      end

      def config(snapshot : Bool? = false, &block)
        if snapshot
          begin
            Error.giterr LibGit.repository_config_snapshot(out config_snapshot, to_unsafe), "Cannot get config"
            config = Config.new(config_snapshot)
            yield config
          ensure
            config.free if config
          end
        else
          begin
              Error.giterr LibGit.repository_config(out cfg, to_unsafe), "Cannot get config"
              config = Config.new(cfg)
              yield config
            ensure
              config.free if config
          end
        end
      end

      def each_fetchhead(&block : EachFetchHeadCb) : Void
        payload = Box.box(block)
        callback : LibGit::RepositoryFetchheadForeachCb = ->(ref : LibC::Char*, remote_url : LibC::Char*, git_oid : LibGit::Oid*, is_merge : LibC::UInt, payload : Void*) do
          cb = Box(EachFetchHeadCb).unbox(payload)
          ref_name = String.new(ref)
          url = String.new(remote_url)
          oid = Oid.new(git_oid)
          merge = is_merge.positive?

          b = cb.call(ref_name, url, oid, merge)

          b.nil? ? 0 : (b ? 0 : 1)
        end

        Error.giterr LibGit.repository_fetchhead_foreach(to_unsafe, callback, payload), "Cannot iterate over fetchhead"
      end

      def checkout_head(options : CheckoutOptions? = CheckoutOptions.default)
        Error.giterr LibGit.checkout_head(to_unsafe, options.to_unsafe_ptr), "Cannot checkout head"
      end

      def revparse_single(text : String)
        Error.giterr LibGit.revparse_single(out obj, to_unsafe, text), "Cant revparse single"

        Object.new(obj)
      end

      def mirror_remote(name : String, url : String)
        remote = create_remote_with_fetchspec(name, url, "+refs/*:refs/*")
        config do |c|
          c.mirror(name)
        end
        remote
      end

      def create_remote(name : String, url : String)
        Error.giterr LibGit.remote_create(out remote, to_unsafe, name, url), "Cannot create remote #{name}"
        Remote.new(remote)
      end

      def create_remote_with_fetchspec(name : String, url : String, refspec : String)
        Error.giterr LibGit.remote_create_with_fetchspec(out remote, to_unsafe, name, url, refspec), "Cannot create remote #{name}"
        Remote.new(remote)
      end

      def create_remote(name : String, url : String, &block)
        remote = create_remote(name, url)
        yield remote
      ensure
        remote.free if remote
      end

      def remote(name : String)
        Error.giterr LibGit.remote_lookup(out remote, to_unsafe, name), "Cannot fetch remote #{name}"
        Remote.new(remote)
      end

      def remotes
        Error.giterr LibGit.remote_list(out strarray, to_unsafe), "Cannot fetch remotes"
        arr = Array(Pointer(UInt8)).new(strarray.count.to_i, strarray.strings.value)
        arr.map do |i|
          remote(String.new(i))
        end
      end

      def remotes(&block)
        rems = remotes
        yield rems
      ensure
        rems.each(&.free) if rems
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
