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

  class Comments
    def take_before(node, source_part)
      range = source_range(node, source_part)
      if range
        return take_up_to_line(range.line - 1)
      else
        return EMPTY_ARRAY
      end
    end

    def take_up_to_line(line)
      last_index = @comments.index { |comment| comment.location.expression.line == line }
      return EMPTY_ARRAY unless last_index

      # TODO: better implementation
      line -= 1
      prev_index = last_index - 1
      while prev_index >= 0 && @comments[prev_index].location.expression.line == line
        line -= 1
        prev_index -= 1
      end
      comments = @comments.select.with_index { |_,i| i > prev_index && i <= last_index }
      @comments.reject! { |c| comments.include?(c) }
      return comments
    end
  end
end
