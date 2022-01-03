require "spec"
require "../src/grits"
require "random/secure"

Spec.after_suite do
  Fixture.clean_all
end

class Fixture
  def self.clean_all
    FileUtils.rm_rf("#{__DIR__}/tmp")
  end

  def self.random_user
    { email: "sean#{Random::Secure.hex(4)}@sean.com", name: "Grits #{Random::Secure.hex(4)}", time: Time.utc }
  end

  def self.write_file(path_to_file, content)
    File.open(path_to_file, "w") { |f| f << content }
  end

  def self.remove_milliseconds_from_time(time)
    Time.parse(time.to_s("%Y-%m-%d %H:%M:%S"), "%Y-%m-%d %H:%M:%S", Time::Location::UTC)
  end

  def self.clone_repo(url, dir, &block)
    path = "#{__DIR__}/tmp/#{dir}"
    begin
      Grits::Repo.clone(url, path) do |repo|
        yield repo, path
      end
    ensure
      FileUtils.rm_rf(path)
    end
  end

  def self.init_repo(**args, &block)
    path = "#{__DIR__}/tmp/#{Random::Secure.hex(5)}"
    begin
      Grits::Repo.init(path, **args) do |repo|
        yield repo, path
      end
    ensure
      FileUtils.rm_rf(path)
    end
  end
end
