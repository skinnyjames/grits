module Grits
  module Error
    def self.giterr(status, errstr : String)
      return if status == LibGit::ErrorCode::Ok.value
      raise Git.new(status, errstr)
    end

    class Git < Exception
      def initialize(code : Int, message)
        @code = LibGit::ErrorCode.from_value(code)
        @message = "#{@code}: #{message}"
      end
    end
  end
end
