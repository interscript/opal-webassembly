require 'base64'
require 'opal/builder_processors'

module Opal
  module BuilderProcessors
    class WASMProcessor < Processor
      handles :wasm

      # Override the initialization, because we really don't want a new line mangling
      def initialize(source, filename, options = {})
        #source += "\n" unless source.end_with?("\n")
        @source, @filename, @options = source, filename, options
        @requires = []
        @required_trees = []
      end

      def source
        module_name = ::Opal::Compiler.module_name(@filename)
        source = Base64.strict_encode64(@source.to_s)
        <<~END
          Opal.modules[#{module_name.inspect}] = function() {
            // WebAssembly module
            var self = Opal.top;
            self.$require("webassembly");
            Opal.WebAssembly.$load_from_base64('#{source}', #{module_name.inspect});
          };
        END
      end

      # No source map support. Required to be mocked for tests.
      def source_map
        o = Object.new
        def o.generated_code; ""; end
        def o.to_h; {version: 3, sections: nil, sources: [], mappings: []}; end
        o
      end

      def requires
        ['webassembly'] + super
      end
    end
  end
end

module Opal
  module WebAssembly
    Processor = ::Opal::BuilderProcessors::WASMProcessor
  end
end
