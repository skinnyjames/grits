module Grits
  alias RemoteCreateCb = (Repo, String, String -> Grits::Remote)

  class Remote
    include Mixins::Pointable

    alias TagStrategy = LibGit::RemoteAutoTagOptionT

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

    def update_tips!(
      callbacks : Remotable::Callbacks? = Remotable::Callbacks.init,
      update_fetchhead : Bool? = true,
      download_tags : TagStrategy? = TagStrategy::DownloadTagsAuto,
      reflog_message : String? = nil
    )

      update = update_fetchhead ? 1 : 0

      Error.giterr LibGit.remote_update_tips(to_unsafe, callbacks.to_unsafe, update, download_tags, reflog_message), "Cant update tips"
    end

    def fetch(refs : Array(String?) = [] of String?, options : FetchOptions? = FetchOptions.default, reflog_message : String? = nil)
      strarray = LibGit::Strarray.new

      stuff = refs.reduce([] of Pointer(UInt8)) do |memo, ref|
        if a = ref
          memo << ref.to_unsafe
        end
        memo
      end

      strarray.strings = stuff
      strarray.count = stuff.size
      strptr = pointerof(strarray)
      Error.giterr LibGit.remote_fetch(to_unsafe, strptr, options.to_unsafe_ptr, reflog_message), "Cannot fetch"
    end

    def refspecs : Array(String)
      strarray = LibGit::Strarray.new
      if ptr = pointerof(strarray)
        begin
          Error.giterr LibGit.remote_get_fetch_refspecs(ptr, to_unsafe), "Can't fetch refspecs"

          arr = Array(Pointer(UInt8)).new(strarray.count.to_i, strarray.strings.value)
          arr.map { |f| String.new(f) }
        ensure
          LibGit.strarray_free(ptr)
        end
      else
        raise Error::Generic.new("Can't fetch refspecs")
      end
    end

    protected def free
      LibGit.remote_free(to_unsafe)
    end
  end
end
