require "./spec_helper"

describe Grits::Diff do
  # Work in progress
  describe "#options" do
    it "context_lines define number of unchanged lines to include in hunk" do
      diff_options = Grits::DiffOptions.default
      diff_options.include_untracked
      diff_options.show_untracked_content
      diff_options.context_lines = 10
      diff_options.on_progress do |diff, old, new|
        puts "OLD: #{old}, NEW: #{new}, DIFF: #{diff.delta(0).files_count}"
        false
      end

      data = <<-EOF
      This is all new
        lines and should
      be present in the new
          Diff
      EOF

      Fixture.clone_default_http do |repo, path|
        File.write("#{path}/saved.txt", data)
        File.write("#{path}/new.txt", data)
        
        File.open("#{path}/file1", "a") do |io|
          io << "yeahh"
        end

        puts Dir.entries(path)

        repo.index do |index|
          index.add_file("saved.txt")

          index.diff_workdir(diff_options) do |diff|
            diff.file_deltas.size.should eq(1)
          end
        end
      end
    end
  end
end