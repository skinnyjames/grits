require "./spec_helper"

describe Grits::Repo do
  describe "transactions" do
    before_each do
      FileUtils.rm_rf("#{__DIR__}/tmp")
    end

    it "should make a transaction" do
      path = "#{__DIR__}/tmp/#{Random::Secure.hex(5)}"
      Grits::Repo.init(path, make: true) do |repo|
        File.open("#{path}/hello.txt", "w") { |f| f << "Hello World" }
        repo.add "hello.txt"
        commit = repo.commit "Hello World"
        commit.message.should eq("Hello World")
      end
    end
  end
end
