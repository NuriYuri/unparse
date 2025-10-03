class BeginNode < OverridableNode
  # @param type [Symbol]
  # @param children [Array<Parser::AST::Node | OverridableNode>]
  # @param props [Hash]
  # @return [Parser::AST::Node]
  def as_node(type = @type, children = @children, props = @props)
    if children && children.size > 1
      return super
    else
      return children ? map_child(children[0]) : nil
    end
  end

  # @param other [Parser::AST::Node | OverridableNode]
  # @return [self]
  def concat(other)
    if other.is_a?(BeginNode)
      @children = @children.dup if @children.frozen?
      @children.concat(other.children)
    else
      raise "Failed to append #{other.type} into BeginNode"
    end
    return self
  end

  # @param other [Parser::AST::Node | OverridableNode]
  # @return [self]
  def push(other)
    @children = @children.dup if @children.frozen?
    @children.push(other)
    return self
  end
end

module WithBeginNode
  def n(type, children, location)
    return BeginNode.new(type, children, { location: }) if type == :begin

    super
  end
end

BuilderPrism.prepend(WithBeginNode)
