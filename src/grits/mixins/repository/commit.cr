module Grits
  module Mixins
    module Repository
      module Commit
        def lookup_commit_by_oid(oid : Grits::Oid) : Grits::Commit
          Error.giterr LibGit.commit_lookup(out commit, to_unsafe, oid.to_unsafe_ptr), "Cannot load commit"
          Grits::Commit.new(commit, self)
        end

        # TODO: validate that the returned ref actually
        # points to a commit
        def commit_at(reference, & : Grits::Commit ->)
          oid = object_id_at(reference)

          commit = lookup_commit_by_oid(oid)
          begin
            yield(commit)
          ensure
            commit.free
          end
        end

        def commit_at_head(&)
          commit_at("HEAD") do |commit|
            yield(commit)
          end
        end

        def object_id_at(reference) : Oid
          Error.giterr LibGit.reference_name_to_id(out oid, to_unsafe, reference), "couldn't reference id"
          Oid.new(oid)
        end
      end
    end
  end
end
