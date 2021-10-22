

module DevopsAssist
  module Gem
    module Gemspec
      include TR::CondUtils 

      class GemspecError < StandardError; end

      def find_gem_name(root)
        spec = find_gemspec(root)
        s = ::Gem::Specification.load(spec)
        s.name
      end

      private
      def find_gemspec(root)
        if is_empty?(root)
          raise GemspecError, "Root path '#{root}' to find_gemspec is empty"
        else
          Dir.glob(File.join(root,"*.gemspec")).first
        end
      end

    end
  end
end

