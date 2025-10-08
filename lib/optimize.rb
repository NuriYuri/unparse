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
end

class SendNode
  MATH_NODE = %i[int float]
  # @param klass [CodeSpace::CodeSpaceClass]
  # @return [OverridableNode]
  def optimize(klass)
    if @target == nil && @method_name == :debug? && @arguments.empty?
      return Parser::AST::Node.new(:false, [], @props)
    elsif @method_name == :release? && @arguments.empty? && $optimize_release
      return Parser::AST::Node.new(:true, [], @props) if @target == nil
      return Parser::AST::Node.new(:true, [], @props) if @target.is_a?(ConstNode) && @target.name == :PSDK_CONFIG && @target.path.size == 1
    # TODO: various PSDK configs optimizations
    end
    @arguments = @arguments.flat_map { |a| a.respond_to?(:optimize) ? a.optimize(klass) : a }
    @target = @target.optimize(klass) if @target.respond_to?(:optimize)

    if @target && MATH_NODE.include?(@target.type)
      if @arguments.size == 1 && MATH_NODE.include?(@arguments[0].type)
        res = @target.children[0].send(@method_name, @arguments[0].children[0])
        return @target.updated(res.is_a?(Integer) ? :int : :float, [res])
      end
    end

    return self
  end
end

class IfNode
  # @param klass [CodeSpace::CodeSpaceClass]
  # @return [OverridableNode]
  def optimize(klass)
    @condition = @condition.optimize(klass) if @condition.respond_to?(:optimize)
    @if_true = @if_true.optimize(klass) if @if_true.respond_to?(:optimize)
    @if_false = @if_false.optimize(klass) if @if_false.respond_to?(:optimize)

    if @condition.type == :true && @if_true
      return @if_true
    elsif @condition.type == :false && @if_false
      return @if_false
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

    return self
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
    def optimize
      @public_instance_methods.each_value do |meth|
        meth.optimize(self)
      end
      @private_instance_methods.each_value do |meth|
        meth.optimize(self)
      end
      @protected_instance_methods.each_value do |meth|
        meth.optimize(self)
      end
    end
  end
end
