require "./spec_helper"

describe Grits::Index do
  describe "#add" do
    it "commits files to disk" do
      repo_path = Fixture.tmp_path

      Grits::Repo.init(repo_path) do |repo|
        File.write("#{repo_path}/top", "content\n")

        repo.index do |stage|
          stage.add(["top"]) do |path, match|
            true
          end

          File.open("#{repo_path}/top", "a") { |io| io.print "more\n" }
        end
      end

      Grits::Repo.open(repo_path.not_nil!) do |repo|
        repo.index do |stage|
          stage.diff_workdir do |diff|
            diff.lines.map(&.content).should eq(["content\n", "more\n"])
          end
        end
      end
    end

    it "clears committed files" do
      repo_path = Fixture.tmp_path

      Grits::Repo.init(repo_path) do |repo|
        File.write("#{repo_path}/top", "content\n")

        repo.index do |stage|
          stage.add(["top"]) do |path, match|
            true
          end

          File.open("#{repo_path}/top", "a") { |io| io.print "more\n" }
        end
      end

      Grits::Repo.open(repo_path.not_nil!) do |repo|
        repo.index do |stage|
          stage.clear
          stage.diff_workdir do |diff|
            diff.lines.map(&.content).should eq([] of String)
          end
        end
      end
    end
  end
  
  describe "#add_files" do
    it "doesn't commit files to disk" do
      repo_path = Fixture.tmp_path

      Grits::Repo.init(repo_path) do |repo|
        File.write("#{repo_path}/top", "content\n")

        repo.index do |stage|
          stage.add_files(["top"]) do |path, match|
            true
          end

          File.open("#{repo_path}/top", "a") { |io| io.print "more\n" }
        end
      end

      Grits::Repo.open(repo_path.not_nil!) do |repo|
        repo.index do |stage|
          stage.diff_workdir do |diff|
            diff.lines.map(&.content).should eq([] of String)
          end
        end
      end
    end
  
    it "takes a callback of matched paths" do
      Fixture.init_repo do |repo, path|
        FileUtils.mkdir_p("#{path}/folder_a")
        FileUtils.mkdir_p("#{path}/folder_b")
        File.write("#{path}/top", "this is top")
        File.write("#{path}/folder_a/a", "this is a")
        File.write("#{path}/folder_b/b", "this is b")

        values = [] of Tuple(String, String)

        repo.index do |stage|
          stage.add_files(["**/a", "**/b"]) do |path, matched_path|
            values << { path, matched_path }
            false
          end
        end

        values.should eq([{"folder_a/a", "**/a"}, {"folder_b/b", "**/b"}])
      end
    end
  end
end
