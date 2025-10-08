class IndexNode < OverridableNode
  # @return [Parser::AST::Node]
  attr_reader :left
  # @return [Array<Parser::AST::Node>]
  attr_reader :indexes
  # @return [Parser::AST::Node | nil]
  attr_reader :right

  def initialize(type, children, props)
    @left, *@indexes, @right = children
    super
  end

  # @param type [Symbol]
  # @param children [Array<Parser::AST::Node | OverridableNode>]
  # @param props [Hash]
  # @return [Parser::AST::Node]
  def as_node(type = @type, children = nil, props = @props)
    super(type, children || [@left, *@indexes, @right], props)
  end
end


module WithIndexNode
  def n(type, children, location)
    return IndexNode.new(type, children, { location: }) if type == :index || type == :indexasgn

    super
  end
end

BuilderPrism.prepend(WithIndexNode)
