require "spec"
require "../src/grits"
require "random/secure"
require "log"

Spec.before_suite do
  Fixture.write_secrets
end

Spec.after_suite do
  Fixture.clean_all
end

class Fixture
  def self.host
    ENV["CI"]? ? "gitea" : "localhost"
  end

  def self.ssh_port
    ENV["CI"]? ? "22" : "222"
  end

  def self.write_secrets
    unless File.exists?(gitea_public_key_path)
      File.open(gitea_public_key_path, "w") do |f|
        f << ENV["GITEA_PUBLIC_KEY"]
      end
    end

    unless File.exists?(gitea_private_key_path)
      File.open(gitea_private_key_path, "w") do |f|
        f << ENV["GITEA_PRIVATE_KEY"]
      end
    end

    unless File.exists?("#{__DIR__}/helpers/gitea/access_token")
      File.open("#{__DIR__}/helpers/gitea/access_token", "w") do |f|
        f << ENV["GITEA_ACCESS_TOKEN"]
      end
    end
  end

  def self.clean_all
    FileUtils.rm_rf("#{__DIR__}/tmp")
  end

  def self.gitea_access_token
    File.read("#{__DIR__}/helpers/gitea/access_token")
  end

  def self.gitea_public_key_path
    "#{__DIR__}/helpers/gitea/gitea.pub"
  end

  def self.gitea_private_key_path
    "#{__DIR__}/helpers/gitea/gitea"
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

  def self.clone_repo(url, dir, *args, &block)
    path = "#{__DIR__}/tmp/#{dir}"
    begin
      Grits::Repo.clone(url, path, *args) do |repo|
        yield repo, path
      end
    ensure
      FileUtils.rm_rf(path)
    end
  end

  def self.tmp_path
    "#{__DIR__}/tmp/#{Random::Secure.hex(5)}"
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

  def self.init_ext_repo(**args, &block)
    path = "#{__DIR__}/tmp/#{Random::Secure.hex(5)}"
    begin
      Grits::Repo.init_ext(path, **args) do |repo|
        yield repo, path
      end
      ensure
      FileUtils.rm_rf(path)
    end
  end
end
