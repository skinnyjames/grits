module Grits
  module Mixins
    module Repository
      module Tree
        def tree_at(ref : String, &)
          commit_at(ref) do |commit|
            commit.tree do |tree|
              yield(tree, commit)
            end
          end
        end

        def lookup_tree(oid : Oid)
          Error.giterr LibGit.tree_lookup(out tree, to_unsafe, oid.to_unsafe_ptr), "couldn't lookup tree"
          Grits::Tree.new(tree, self)
        end
  
        def lookup_tree(oid : Oid, &)
          tree = lookup_tree(oid)
          begin
            yield(tree)
          ensure
            tree.free
          end
        end
  
        def lookup_tree(sha : String)
          lookup_tree Oid.from_sha(sha)
        end
  
        def lookup_tree(sha : String, &)
          tree = lookup_tree(sha)
          begin
            yield(tree)
          ensure
            tree.free
          end
        end
      end
    end
  end
end
