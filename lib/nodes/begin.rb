class BeginNode < OverridableNode
  CLASS_LIKE_CHILDREN = %i[class sclass module]
  OPERATORS = %i[/ * - + ** % ^ & | ~ ! > < >= <=]
  # @param type [Symbol]
  # @param children [Array<Parser::AST::Node | OverridableNode>]
  # @param props [Hash]
  # @return [Parser::AST::Node]
  def as_node(type = @type, children = @children, props = @props)
    return super unless children

    children = children.reject { |c| c.is_a?(OverridableNode) && c.removed }
    return super(type, children, props) if children.size > 1

    child = children[0]
    return super unless child

    return map_child(child) if child.is_a?(SendNode) && !OPERATORS.include?(child.method_name) && !child.method_name.end_with?('=')
    return map_child(child) if CLASS_LIKE_CHILDREN.include?(child.type)

    return super(type, children, props) 
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
