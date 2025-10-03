module Unparser
  class Emitter
    class Args
      def emit_block_arguments
        delimited(normal_arguments)
        emit_shadowargs
      end
    end
  end
end
