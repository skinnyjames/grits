require "./spec_helper"

describe Grits::Diff do
  # Work in progress
  describe "#options" do
    it "can show untracked content" do
      diff_options = Grits::DiffOptions.default
      diff_options.include_untracked
      diff_options.show_untracked_content

      data = <<-EOF
      This is all new
        lines and should
      be present in the new
          Diff
      EOF

      Fixture.clone_default_http do |repo, path|
        File.write("#{path}/saved.txt", data)
        File.write("#{path}/new.txt", data)
      
        repo.index do |index|
          index.diff_workdir(diff_options) do |diff|
            diff.file_deltas.size.should eq(2)
          end
        end
      end
    end
  end
end