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

    class If
      private

      def dispatch
        if postcondition?
          emit_postcondition
        elsif ternary?
          emit_ternary
        else
          emit_normal
        end
      end

      def ternary?
        ib = if_branch
        eb = else_branch
        return ib && eb && ib.location.expression.line == eb.location.expression.line
      end

      def postcondition?
        return false unless if_branch.nil? ^ else_branch.nil?

        body = if_branch || else_branch

        # I have no clue what first_assignment_in? really does but if AST location says body came first, it goes first :v
        return true if body.location.expression.end_pos < condition.location.expression.begin_pos
        return local_variable_scope.first_assignment_in?(body, condition)
      end
    end

    class Block
      private

      def need_do?
        b = body
        # Respect basic rules of blocks, no multi line curly bracket blocks
        return true if b && target.location.expression.line < b.location.expression.line
        return b && (n_rescue?(b) || n_ensure?(b))
      end

      def emit_optional_body_ensure_rescue(body)
        return super if need_do? || !body
        return super if n_begin?(body)
        write(' ')
        emit_body(body, indent: false)
        write(' ')
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

  module Writer
    class Send
      class Binary
        private

        def emit_right
          right = children.fetch(2)
          if n_send?(right)
            detail = NodeDetails::Send.new(right)
            return writer_with(Binary, node: right).dispatch if detail.binary_syntax_allowed?
          end
          emit_send_regular(right)
        end
      end
    end
  end
end
