class IfNode < OverridableNode
  # @return [Parser::AST::Node]
  attr_reader :condition
  # @return [Parser::AST::Node | nil]
  attr_reader :if_true
  # @return [Parser::AST::Node | nil]
  attr_reader :if_false

  def initialize(type, children, props)
    @condition, @if_true, @if_false = children
    super
  end

  # @param type [Symbol]
  # @param children [Array<Parser::AST::Node | OverridableNode>]
  # @param props [Hash]
  # @return [Parser::AST::Node]
  def as_node(type = @type, children = nil, props = @props)
    super(type, children || [@condition, @if_true, @if_false], props)
  end
end

module WithIfNode
  def n(type, children, location)
    return IfNode.new(type, children, { location: }) if type == :if

    super
  end
end

BuilderPrism.prepend(WithIfNode)
