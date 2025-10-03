module Unparser
  class Emitter
    class Args
      def emit_block_arguments
        delimited(normal_arguments)
        emit_shadowargs
      end
    end

    class Assignment
      def emit_array
        right_emitter.write_to_buffer
      end
    end
  end
end
