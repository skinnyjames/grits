module Grits
  module Error
    def self.giterr(status, errstr : String)
      return if status == LibGit::ErrorCode::Ok.value
      begin
        raise Git.new(status, errstr)
      ensure
        LibGit.err_clear
      end
    end

    class Generic < Exception; end

    class Git < Exception
      def initialize(code : Int, message)
        @code = LibGit::ErrorCode.from_value(code)
        lib_git_error = LibGit.error_last.value
        @message = "#{@code}: #{message}\n  #{String.new(lib_git_error.message)}"
      end
    end
  end
end
