module Grits
  struct DiffFindOptions
    def self.default
      # really think about versioning in constants
      options = LibGit::DiffFindOptions.new
      Error.giterr LibGit.diff_find_options_init(pointerof(options), 1), "Couldn't init diff options"
      new(options)
    end

    def initialize(@raw : LibGit::DiffFindOptions); end
  end
end