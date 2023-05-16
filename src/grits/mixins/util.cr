module Grits
  module Mixins
    module Util
      protected def convert_to_strarray(strings : Array(String))
        strarray = LibGit::Strarray.new
        stuff = strings.reduce([] of Pointer(UInt8)) do |memo, ref|
          if a = ref
            memo << a.to_unsafe
          end
          memo
        end
  
        strarray.strings = stuff
        strarray.count = stuff.size
        strarray
      end

      protected def flag_value(flags)
        return 0 if flags.empty?

        flags.map(&.value).reduce do |memo, val|
          memo | val
        end
      end
    end    
  end
end
