class AsgnNode < OverridableNode
  # @return [Parser::AST::Node]
  attr_reader :left
  # @return [Parser::AST::Node | nil]
  attr_reader :right

  def initialize(type, children, props)
    @left, @right = children
    super
  end

  # @param type [Symbol]
  # @param children [Array<Parser::AST::Node | OverridableNode>]
  # @param props [Hash]
  # @return [Parser::AST::Node]
  def as_node(type = @type, children = nil, props = @props)
    super(type, children || [@left, @right], props)
  end
end

class OpAsgnNode < OverridableNode
  # @return [Parser::AST::Node]
  attr_reader :left
  # @return [Parser::AST::Node]
  attr_reader :right
  # @return [Symbol]
  attr_reader :operator

  def initialize(type, children, props)
    @left, @operator, @right = children
    super
  end

  # @param type [Symbol]
  # @param children [Array<Parser::AST::Node | OverridableNode>]
  # @param props [Hash]
  # @return [Parser::AST::Node]
  def as_node(type = @type, children = nil, props = @props)
    super(type, children || [@left, @operator, @right], props)
  end
end

class MultipleLeftHandSideNode < OverridableNode
end

module WithAsgnNode
  ASGN = %i[lvasgn ivasgn cvasgn gvasgn masgn or_asgn and_asgn]
  def n(type, children, location)
    return AsgnNode.new(type, children, { location: }) if ASGN.include?(type)
    return OpAsgnNode.new(type, children, { location: }) if type == :op_asgn
    return MultipleLeftHandSideNode.new(type, children, { location: }) if type == :mlhs

    super
  end

  def updated(type = nil, children = nil, props = nil)
    return AsgnNode.new(type, children || @children, props || { location: @location }) if ASGN.include?(type)
    return OpAsgnNode.new(type, children || @children, props || { location: @location }) if type == :op_asgn
    super
  end
end

Parser::AST::Node.prepend(WithAsgnNode)
BuilderPrism.prepend(WithAsgnNode)
