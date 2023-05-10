require "./spec_helper"

describe Grits::Diff do
  it "can diff workdir with stage" do
    Fixture.clone_default_http do |repo, path|
      File.open("#{path}/file1", "a") do |io|
        io << "another line"
        io << "again another line"
      end

      repo.index do |stage|
        # lines is 3, one is a missing a newline and 2 added.
        stage.diff_workdir do |diff|
          diff.files.size.should eq(1)
          diff.hunks.size.should eq(1)
          diff.lines.size.should eq(3)
          diff.deltas(Grits::DiffDeltaType::Modified).should eq(1)
        end
      end
    end
  end

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
            diff.files.size.should eq(2)
          end
        end
      end
    end
  end
end
