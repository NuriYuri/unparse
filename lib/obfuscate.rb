module MethodNodeObfuscate
  # @return [OverridableNode]
  def obfuscate(*)
    return self unless @content

    lv = Hash.new { |h, k| h[k] = :"l#{h.size}" }
    lv[:_] = :_
    @arguments.obfuscate(lv) if @arguments.respond_to?(:obfuscate)
    @content.obfuscate(lv) if @content.respond_to?(:obfuscate)
    return self
  end
end

MethodNode.prepend(MethodNodeObfuscate)
SingletonMethodNode.prepend(MethodNodeObfuscate)

class OverridableNode
  # @param lv [Hash]
  # @return [OverridableNode]
  def obfuscate(lv)
    return self unless @children
    return self if type == :casgn

    @children.each { |c| c.respond_to?(:obfuscate) ? c.obfuscate(lv) : c }

    return self
  end
end

class SendNode
  # @param lv [Hash]
  # @return [OverridableNode]
  def obfuscate(lv)
    @target.obfuscate(lv) if @target.respond_to?(:obfuscate)
    @arguments.each { |c| c.respond_to?(:obfuscate) ? c.obfuscate(lv) : c }
    @content.obfuscate(lv) if @content.respond_to?(:obfuscate)

    return self
  end
end

class IfNode
  # @param lv [Hash]
  # @return [OverridableNode]
  def obfuscate(lv)
    @condition.obfuscate(lv) if @condition.respond_to?(:obfuscate)
    @if_true.obfuscate(lv) if @if_true.respond_to?(:obfuscate)
    @if_false.obfuscate(lv) if @if_false.respond_to?(:obfuscate)
    return self
  end
end

class AndOrNode
  # @param lv [Hash]
  # @return [OverridableNode]
  def obfuscate(lv)
    @left.obfuscate(lv) if @left.respond_to?(:obfuscate)
    @right.obfuscate(lv) if @right.respond_to?(:obfuscate)
    return self
  end
end

class AsgnNode
  # @param lv [Hash]
  # @return [OverridableNode]
  def obfuscate(lv)
    if @type == :lvasgn
      @left = lv[@left]
    elsif @type == :masgn
      @left.children.each { |c| c.obfuscate(lv) if c.respond_to?(:obfuscate)}
    elsif @left.respond_to?(:obfuscate)
      @left.obfuscate(lv)
    end
    @right = @right.obfuscate(lv) if @right.respond_to?(:obfuscate)
    return self
  end
end

class LvarNode
  # @param lv [Hash]
  # @return [OverridableNode]
  def obfuscate(lv)
    @name = lv[@name]
    return self
  end
end

class OpAsgnNode
  # @param lv [Hash]
  # @return [OverridableNode]
  def obfuscate(lv)
    if @type == :lvasgn
      @left = lv[@left]
    elsif @type == :masgn
      @left.children.each { |c| c.children[0] = lv[c.children[0]] }
    elsif @left.respond_to?(:obfuscate)
      @left.obfuscate(lv)
    end
    @right = @right.obfuscate(lv) if @right.respond_to?(:obfuscate)
    return self
  end
end

class IndexNode
  # @param lv [Hash]
  # @return [OverridableNode]
  def obfuscate(lv)
    @left.obfuscate(lv) if @left.respond_to?(:obfuscate)
    @indexes.map { |c| c.respond_to?(:obfuscate) ? c.obfuscate(lv) : c }
    @right.obfuscate(lv) if @right.respond_to?(:obfuscate)
    return self
  end
end

class BlockNode
  # @param lv [Hash]
  # @return [OverridableNode]
  def obfuscate(lv)
    @left.obfuscate(lv) if @left.respond_to?(:obfuscate)
    inside_lv = lv.dup
    @arguments.obfuscate(inside_lv) if @arguments.respond_to?(:obfuscate)
    @content.obfuscate(inside_lv) if @content.respond_to?(:obfuscate)

    return self
  end
end

class OptArgNode < OverridableNode
  # @param lv [Hash]
  # @return [OverridableNode]
  def obfuscate(lv)
    @children = @children.map { |c| c.is_a?(Symbol) ? lv[c] : (c.respond_to?(:obfuscate) ? c.obfuscate(lv) : c) }
    return self
  end
end

class KwOptArgNode < OverridableNode
  # @param lv [Hash]
  # @return [OverridableNode]
  def obfuscate(lv)
    @children.each { |c| lv[c] = c if c.is_a?(Symbol) }
    @children = @children.map { |c| c.is_a?(Symbol) ? lv[c] : (c.respond_to?(:obfuscate) ? c.obfuscate(lv) : c) }
    return self
  end
end

class ArgNode < OverridableNode
  # @param lv [Hash]
  # @return [OverridableNode]
  def obfuscate(lv)
    if type == :kwarg
      @children.each { |c| lv[c] = c if c.is_a?(Symbol) }
    end
    @children = @children.map { |c| c.is_a?(Symbol) ? lv[c] : (c.respond_to?(:obfuscate) ? c.obfuscate(lv) : c) }
    return self
  end
end

class ObjCKWArgNode < OverridableNode
  # @param lv [Hash]
  # @return [OverridableNode]
  def obfuscate(lv)
    @children = @children.map { |c| c.is_a?(Symbol) ? lv[c] : c }
    return self
  end
end


class CodeSpace
  def obfuscate
    @all_classes.each do |klass|
      puts "Obfuscating: #{klass.path}"
      klass.obfuscate
    end
  end

  class CodeSpaceClass
    def obfuscate
      @public_instance_methods.each_value do |meth|
        meth.obfuscate
      end
      @private_instance_methods.each_value do |meth|
        meth.obfuscate
      end
      @protected_instance_methods.each_value do |meth|
        meth.obfuscate
      end
    end
  end
end
