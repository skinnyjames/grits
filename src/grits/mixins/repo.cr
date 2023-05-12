require "./repository/*"

module Grits
  alias OpenRepoType = LibGit::RepositoryTypes

  module Mixins
    module Repo
      include Repository::Tree
      include Repository::Commit

      alias Item = LibGit::RepositoryItemT
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

      def configured_identity : Tuple(String?, String?)
        Error.giterr LibGit.repository_ident(out name, out email, to_unsafe), "Cannot get ident for repository"
      
        { copy_to_string(name), copy_to_string(email) }
      end

      def configure_identity(name : String? = nil, email : String? = nil) : Nil
        name_ptr = name ? pointerof(name) : Pointer(LibC::Char).null
        email_ptr = name ? pointerof(email) : Pointer(LibC::Char).null

        Error.giterr LibGit.repository_set_ident(to_unsafe, name, email), "Cannot set ident for repository"
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

      def worktree
        Error.giterr LibGit.worktree_open_from_repository(out worktree, to_unsafe), "Couldn't open worktree"
        Worktree.new(worktree, self)
      end

      def worktree(&)
        tree = worktree
        begin
          yield(tree)
        ensure
          tree.free
        end
      end

      def worktree?
        LibGit.repository_is_worktree(to_unsafe).positive?
      end

      def worktree_head(worktree : String) : Reference?
        return nil unless worktree?

        Error.giterr LibGit.repository_head_for_worktree(out ref, to_unsafe, worktree), "Can't fetch head for worktree"
        return Reference.new(ref)
      end

      def worktree_head_detached?(worktree : String)
        LibGit.repository_head_detached_for_worktree(to_unsafe, worktree).positive?
      end

      def shallow? : Bool
        LibGit.repository_is_shallow(to_unsafe) == 1
      end

      def namespace : String?
        val = LibGit.repository_get_namespace(to_unsafe)
        val.null? ? nil : String.new(val)
      end

      def hash_file(path : String, type : Object::Type, as_path : String? = nil)
        Error.giterr LibGit.repository_hashfile(out oid, to_unsafe, path, type, as_path), "Cannot hash file"
        Oid.new(oid)
      end

      def diff_workdir(options = DiffOptions.default) : Diff
        Error.giterr LibGit.diff_index_to_workdir(out diff, to_unsafe, Pointer(Void).null.as(LibGit::Index), options.to_unsafe_ptr), "Cannot diff index with repo workdir"
  
        Diff.new(diff)
      end

      def diff_workdir(options = DiffOptions.default, &)
        diff = diff_workdir(options)
        yield(diff)
        diff.free
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
          oid = Oid.new(git_oid.value)
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

      def lookup_commit(sha : String) : Commit
        oid = Oid.from_sha(sha)
        lookup_commit_by_oid(oid)
      end


      def item_path(item : Item)
        b = Buffer.create
        Error.giterr LibGit.repository_item_path(b.to_unsafe_ptr, to_unsafe, item), "Can't find item path"
        str = b.to_s
        b.free
        str
      end

      def object_database(&block)
        db = Odb.from_repo(self)
        yield db
      ensure
        db.free if db
      end

    end
  end
end
