module Grits
  # @param <String> the tag name.
  # @param <Grits::Oid> the tag id
  # @return <Bool> abort the iteration?
  alias EachTagInfo = (String, Grits::Oid -> Bool)
  record TagData, name : String, sha : String, message : String
  
  struct TagInfo
    getter :name, :oid, :repo

    def initialize(@repo : Repo, @name : String, @oid : Grits::Oid); end

    def valid?
      Grits::Tag.valid_name?(name)
    end

    def resolve(&block : Tag | Commit | Tree ->)
      if annotated?
        as_tag do |tag|
          block.call(tag)
        end
      elsif lightweight?
        as_commit do |commit|
          block.call(commit)
        end
      elsif tree?
        as_tree do |tree|
          block.call(tree)
        end
      end
    end

    def annotated?
      obj = oid.object(repo)
      annotated = obj.tag?
      obj.free
      annotated
    end

    def lightweight?
      obj = oid.object(repo)
      light = obj.commit?
      obj.free
      light      
    end

    def tree?
      obj = oid.object(repo)
      tree = obj.tree?
      obj.free
      tree      
    end

    def as_tag(&block : Tag ->)
      tag = Tag.lookup(repo, oid, name: name)
      begin
        block.call(tag)
      ensure
        tag.free
      end
    end

    def as_commit(&block : Commit ->)
      commit = Commit.lookup(repo, oid)
      begin
        block.call(commit)
      ensure
        commit.free
      end
    end
    
    def as_tree(&block : Tree ->)
      tree = Tree.lookup(repo, oid.to_unsafe)
      begin
        block.call(tree)
      ensure
        tree.free
      end
    end
  end

  class TagForeachCallbacks < CallbacksState
    define_callback EachTagInfo, tag_info
  end

  struct TagIterator
    include Mixins::Callbacks

    @callbacks_state = TagForeachCallbacks.new
    @tag_info_cb : LibGit::TagForeachCb = -> (name : LibC::Char*, oidref : LibGit::Oid*, payload : Void*) {0}

    define_callback tag_info, EachTagInfo, callbacks_state

    def execute(repo : Grits::Repo)
      payload = Box(TagForeachCallbacks).box(@callbacks_state)

      add_callbacks

      Error.giterr(LibGit.tag_foreach(repo.to_unsafe, @tag_info_cb, payload), "Could not iterate tags")
    end

    protected def add_callbacks
      @callbacks_state.callbacks.each do |cb|
        case cb
        when :tag_info
          @tag_info_cb = -> (name : LibC::Char*, oidref : LibGit::Oid*, payload : Void*) do
            if block = Box(TagForeachCallbacks).unbox(payload).on_tag_info

              tag_name = String.new(name)
              oid = Grits::Oid.new(oidref.value)

              res = block.call(tag_name, oid)
              return res ? 0 : 1
            else
              0
            end
          end
        end
      end
    end
  end

  module Mixins
    module Repository
      module Tag
        def tags
          tag_datas = [] of TagData | CommitData | TreeData
          each_tag do |tag_or_commit_or_tree|
            tag_datas << tag_or_commit_or_tree.data
            true
          end

          tag_datas
        end

        def each_tag(&block : Grits::Tag | Grits::Commit | Grits::Tree -> Bool)
          each_tag_info do |info|
            # skip if tag isn't annotated
            if info.valid?
              info.resolve do |tag_or_commit|
                block.call(tag_or_commit)
              end
            end

            true
          end
        end

        def tag_list : Array(String)
          strarray = LibGit::Strarray.new
          ptr = pointerof(strarray)

          Error.giterr(LibGit.tag_list(ptr, to_unsafe), "Can't fetch tag list")

          slice = strarray.strings.to_slice(strarray.count)
          strings = slice.map { |s| String.new(s) }.to_a

          LibGit.strarray_free(ptr)

          strings.sort
        end

        def each_tag_info(&block : Grits::TagInfo -> Bool)
          datas = [] of Tuple(String, Oid)

          iterator = TagIterator.new
          iterator.on_tag_info do |tag_name, oid|
            info = Grits::TagInfo.new(self, tag_name, oid)
            block.call(info)
          end

          iterator.execute(self)
        end
      end
    end
  end
end
