module MethodNodeOptimize
  # @param klass [CodeSpace::CodeSpaceClass]
  # @return [OverridableNode]
  def optimize(klass)
    return self unless @content

    @content = @content.optimize(klass) if @content.respond_to?(:optimize)
    return self
  end
end

MethodNode.prepend(MethodNodeOptimize)
SingletonMethodNode.prepend(MethodNodeOptimize)

class OverridableNode
  # @param klass [CodeSpace::CodeSpaceClass]
  # @return [OverridableNode]
  def optimize(klass)
    return self unless @children
    return self if type == :casgn

    @children = @children.flat_map { |c| c.respond_to?(:optimize) ? c.optimize(klass) : c }

    return self
  end

  private

  def s(type, *children)
    Parser::AST::Node.new(type, children, @props)
  end
end

class SendNode
  MATH_NODE = %i[int float]
  MATH_OPS = %i[+ - * / ** ^]
  # @param klass [CodeSpace::CodeSpaceClass]
  # @return [OverridableNode]
  def optimize(klass)
    if @target == nil && @method_name == :debug? && @arguments.empty?
      return Parser::AST::Node.new(:false, [], @props)
    elsif @method_name == :release? && @arguments.empty? && $optimize_release
      return Parser::AST::Node.new(:true, [], @props) if @target == nil
      return Parser::AST::Node.new(:true, [], @props) if @target.is_a?(ConstNode) && @target.name == :PSDK_CONFIG && @target.path.size == 1
    elsif is_call_to_remove?
      @removed = true
      return self
    elsif is_block_call?(klass)
      return to_while_loop
    # TODO: various PSDK configs optimizations
    end
    @arguments = @arguments.flat_map { |a| a.respond_to?(:optimize) ? a.optimize(klass) : a }
    @target = @target.optimize(klass) if @target.respond_to?(:optimize)

    if @target && MATH_NODE.include?(@target.type) && MATH_OPS.include?(method_name)
      if @arguments.size == 1 && MATH_NODE.include?(@arguments[0].type)
        res = @target.children[0].send(@method_name, @arguments[0].children[0])
        return @target.updated(res.is_a?(Integer) ? :int : :float, [res])
      end
    end

    return self
  end

  private

  BLOCK_ARGS = %i[block_pass block]

  # @param klass [CodeSpace::CodeSpaceClass]
  def is_block_call?(klass)
    return klass.block_to_while_allowed && !@arguments.empty? &&
      @arguments.last.type == :block_pass && @arguments.last.children[0]&.type == :sym
  end

  def is_call_to_remove?
    return true if @method_name == :log_debug && @target == nil
    return true if @target.is_a?(ConstNode) && @target.path.size == 2 && @target.path[0] == :Yuki && @target.name == :ElapsedTime

    return false
  end

  def to_while_loop
    raise "Unsupported enumerator #{@method_name}" if @method_name != :each

    return [
      s(:lvasgn, :_i, s(:int, 0)),
      s(:lvasgn, :_l, s(:send, @target, :size)),
      s(:while,
        s(:send, s(:lvar, :_i), :<, s(:lvar, :_l)),
        s(:begin, 
          s(:send, s(:index, @target, s(:lvar, :_i)), @arguments.last.children[0].children[0]),
          s(:op_asgn, s(:lvar, :_i), :+, s(:int, 1))
        )
      )
    ]
  end
end

class IfNode
  # @param klass [CodeSpace::CodeSpaceClass]
  # @return [OverridableNode]
  def optimize(klass)
    @condition = @condition.optimize(klass) if @condition.respond_to?(:optimize)
    @if_true = @if_true.optimize(klass) if @if_true.respond_to?(:optimize)
    @if_false = @if_false.optimize(klass) if @if_false.respond_to?(:optimize)

    if @condition.type == :true
      return @if_true if @if_true
      @removed = true
      return self
    elsif @condition.type == :false
      return @if_false if @if_false
      @removed = true
      return self
    end
    return self
  end
end

class AndOrNode
  # @param klass [CodeSpace::CodeSpaceClass]
  # @return [OverridableNode]
  def optimize(klass)
    @left = @left.optimize(klass) if @left.respond_to?(:optimize)
    @right = @right.optimize(klass) if @right.respond_to?(:optimize)

    is_left_true = @left.type == :true
    is_left_false = @left.type == :false || @left.type == :nil
    is_and = @type == :and
    is_or = @type == :or

    if (is_left_true && is_and) || (is_left_false && is_or)
      return @right
    elsif (is_left_true && is_or)
      return @left
    elsif (is_left_false && is_and)
      return @left
    elsif (@right.type == :true && is_and) || (@right.type == :false && is_or)
      return @left
    # Note: not optimizing for right when right is true or false and makes the whole condition true or false because (stuff(xyz) || true) would not work anymore
    end
    return self
  end
end

class AsgnNode
  # @param klass [CodeSpace::CodeSpaceClass]
  # @return [OverridableNode]
  def optimize(klass)
    @right = @right.optimize(klass) if @right.respond_to?(:optimize)
    return self
  end
end

class OpAsgnNode
  # @param klass [CodeSpace::CodeSpaceClass]
  # @return [OverridableNode]
  def optimize(klass)
    @right = @right.optimize(klass) if @right.respond_to?(:optimize)
    return self
  end
end

class IndexNode
  # @param klass [CodeSpace::CodeSpaceClass]
  # @return [OverridableNode]
  def optimize(klass)
    @indexes = @indexes.flat_map { |c| c.respond_to?(:optimize) ? c.optimize(klass) : c }
    @right = @right.optimize(klass) if @right.respond_to?(:optimize)
    return self
  end
end

class ConstNode
  CONST_LITERALS = %i[int float sym]
  # @param klass [CodeSpace::CodeSpaceClass]
  # @return [OverridableNode]
  def optimize(klass)
    value = klass.const_get(@path)
    return self unless value
    return self unless value.is_a?(Parser::AST::Node)
    return value if CONST_LITERALS.include?(value.type)

    return self
  end
end

class BlockNode
  # @param klass [CodeSpace::CodeSpaceClass]
  # @return [OverridableNode]
  def optimize(klass)
    @left = @left.optimize(klass) if @left.respond_to?(:optimize)
    @arguments = @arguments.optimize(klass) if @left.respond_to?(:optimize)
    @content = @content.optimize(klass) if @content.respond_to?(:optimize)

    if klass.block_to_while_allowed && @left.is_a?(SendNode)
      return to_while_loop
    end
    return self
  end

  def to_while_loop
    method_name = @left.method_name
    target = @left.target
    proc_args = @arguments.children.map { |c| c.type == :arg ? c.children[0] : c.children[0].children[0] }

    case method_name
    when :each
      i = :"_#{proc_args[0]}_i"
      l = :"_#{proc_args[0]}_l"
      return [
        s(:lvasgn, i, s(:int, 0)),
        s(:lvasgn, l, s(:send, target, :size)),
        s(:while,
          s(:send, s(:lvar, i), :<, s(:lvar, l)),
          s(:begin,
            s(:lvasgn, proc_args[0], s(:index, target, s(:lvar, i))),
            *(@content.is_a?(BeginNode) ? @content.children : [@content]).flatten,
            s(:op_asgn, s(:lvar, i), :+, s(:int, 1))
          )
        )
      ]
    when :each_with_index
      i = proc_args[1]
      l = :"_#{proc_args[0]}_l"
      return [
        s(:lvasgn, i, s(:int, 0)),
        s(:lvasgn, l, s(:send, target, :size)),
        s(:while,
          s(:send, s(:lvar, i), :<, s(:lvar, l)),
          s(:begin,
            s(:lvasgn, proc_args[0], s(:index, target, s(:lvar, i))),
            *(@content.is_a?(BeginNode) ? @content.children : [@content]).flatten,
            s(:op_asgn, s(:lvar, i), :+, s(:int, 1))
          )
        )
      ]
    when :times
      i = proc_args[0]
      l = target
      return [
        s(:lvasgn, i, 0),
        s(:while,
          s(:send, s(:lvar, i), :<, l),
          s(:begin,
            *(@content.is_a?(BeginNode) ? @content.children : [@content]).flatten,
            s(:op_asgn, s(:lvar, i), :+, s(:int, 1))
          )
        )
      ]
    when :upto
      i = proc_args[0]
      l = @left.arguments[0]
      return [
        s(:lvasgn, i, target),
        s(:while,
          s(:send, s(:lvar, i), :<=, l),
          s(:begin,
            *(@content.is_a?(BeginNode) ? @content.children : [@content]).flatten,
            s(:op_asgn, s(:lvar, i), :+, s(:int, 1))
          )
        )
      ]
    else
      raise "Unsupported enumerator #{method_name}"
    end
  end
end

class NotNode
  # @param klass [CodeSpace::CodeSpaceClass]
  # @return [OverridableNode]
  def optimize(klass)
    if child = @children[0]
      return child.updated(:false) if child.type == :true
      return child.updated(:true) if child.type == :false || child.type == :nil
    end

    return self
  end
end

class CodeSpace
  def optimize
    @all_classes.each do |klass|
      puts "Optimizing: #{klass.path}"
      klass.optimize
    end
  end

  class CodeSpaceClass
    # @return [Boolean]
    attr_reader :block_to_while_allowed
    def optimize
      @public_instance_methods.each_value do |meth|
        @block_to_while_allowed = is_block_to_while_allowed?(meth.name)
        meth.optimize(self)
      end
      @private_instance_methods.each_value do |meth|
        @block_to_while_allowed = is_block_to_while_allowed?(meth.name)
        meth.optimize(self)
      end
      @protected_instance_methods.each_value do |meth|
        @block_to_while_allowed = is_block_to_while_allowed?(meth.name)
        meth.optimize(self)
      end
      optimize_accessor(:reader, @reader_attributes)
      optimize_accessor(:writer, @writer_attributes)
      optimize_accessor(:accessor, @accessor_attributes)
      @constants.each_value { |c| c.optimize(self) if c.respond_to?(:optimize) && !c.is_a?(CodeSpaceClass) }
    end

    # @param type [Symbol]
    # @param accessors [Array<Symbol>]
    def optimize_accessor(type, accessors)
      return if accessors.empty?
      return if @accessor_nodes[type].size <= 1

      first, *rest = @accessor_nodes[type]
      props = first.props
      first.instance_variable_set(:@arguments, accessors.map { |n| Parser::AST::Node.new(:sym, [n], props) })
      rest.each { |n| n.removed = true }
    end

    private

    ALLOWED_PATHS = [
      [:cbase, :Yuki, :Tilemap],
      [:cbase, :Yuki, :Tilemap, :MapData]
    ]
    ALLOWED_METHODS = [
      [:draw, :update_position],
      [:draw_map]
    ]

    # @param method_name [Symbol]
    # @return [Boolean]
    def is_block_to_while_allowed?(method_name)
      path_index = ALLOWED_PATHS.index(@path)
      return false unless path_index

      return ALLOWED_METHODS[path_index]&.include?(method_name) || false
    end
  end
end
