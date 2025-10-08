class AndOrNode < OverridableNode
  # @return [Parser::AST::Node | nil]
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

module WithAndOrNode
  def n(type, children, location)
    return AndOrNode.new(type, children, { location: }) if type == :or || type == :and

    super
  end
end

BuilderPrism.prepend(WithAndOrNode)
