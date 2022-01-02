# module Grits
#   struct Signature
#     include Mixins::Pointable
#
#     def self.make(name : String, email : String, time : Time)
#       stamp = LibGit::Time.new(time: time.to_unix, offset: time.offset)
#       Error.giterr LibGit.signature_new(out signature, name, email, stamp, time.offset), "Cannot create signature"
#       new(signature)
#     end
#
#     def self.now(name : String, email : String)
#       Error.giterr LibGit.signature_now(out signature, name, email), "Cannot Create Signature"
#       new(signature)
#     end
#
#     def initialize(@raw : LibGit::Signature); end
#
#     def free
#       LibGit.signature_free(pointer)
#     end
#   end
#
#   class CommitBuilder
#     property :message, :author, :committer, :ref, :tree, :encoding, :parents
#
#     def self.build(repo : Repo, **args, &block)
#       builder = new(repo, **args)
#       yield builder
#       builder
#     end
#
#     def initialize(
#       @repo : Repo,
#       *,
#       @message : String,
#       @author : Signature? = nil,
#       @committer : Signature? = nil,
#       @ref : String = "HEAD",
#       @tree : Tree? = nil,
#       @encoding : String = "UTF-8",
#       @committed_at : Time? = nil,
#     )
#     end
#
#     def commit_to_parent(parent : Pointer(Commit))
#       raise "Need a commit message" if @message.nil?
#
#       author_signature, committer_signature = handle_signature
#       commit_tree = tree || default_tree
#
#       LibGit.commit_create(out commit_id, @repo.raw, ref, author_signature.pointer, committer_signature.pointer, encoding, message, commit_tree.raw, 1, parent)
#       Commit.lookup(@repo, pointerof(commit_id))
#     end
#
#     def commit! : Commit
#       raise "Need a commit message" if @message.nil?
#
#       author_signature, committer_signature = handle_signature
#       commit_tree = tree || default_tree
#
#       LibGit.commit_create(out commit_id, @repo.raw, ref, author_signature.pointer, committer_signature.pointer, encoding, message, commit_tree.raw, 0, nil)
#       Commit.lookup(@repo, pointerof(commit_id))
#     end
#
#     def sign_with_defaults!
#       author = committer = default_signature
#     end
#
#     private def handle_signature : Array(Signature)
#       [(author || default_signature), (committer || default_signature)]
#     end
#
#     private def default_parent
#       Error.giterr LibGit.reference_name_to_id(out parent_id, @repo.raw, ref), "Can't find head of current tree"
#       Commit.lookup(@repo, pointerof(parent_id))
#     end
#
#     private def default_tree
#       Error.giterr LibGit.index_write_tree(out tree_oid, @repo.index.raw), "Could not read tree from index"
#       Tree.lookup(@repo, tree_oid)
#     end
#
#     private def default_signature : Signature
#       Error.giterr LibGit.signature_default(out signature, @repo.raw), "Signature invalid"
#       Signature.new(signature.value)
#     end
#   end
# end
