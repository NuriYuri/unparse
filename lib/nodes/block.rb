class BlockNode < OverridableNode
  # @return [Parser::AST::Node]
  attr_reader :left
  # @return [Parser::AST::Node]
  attr_reader :arguments
  # @return [Parser::AST::Node]
  attr_reader :content

  def initialize(type, children, props)
    @left, @arguments, @content = children
    super
  end

  # @param type [Symbol]
  # @param children [Array<Parser::AST::Node | OverridableNode>]
  # @param props [Hash]
  # @return [Parser::AST::Node]
  def as_node(type = @type, children = nil, props = @props)
    super(type, children || [@left, @arguments, @content], props)
  end
end
class BlockPass < OverridableNode
end

module WithBlockNode
  def n(type, children, location)
    return BlockNode.new(type, children, { location: }) if type == :block
    return BlockPass.new(type, children, { location: }) if type == :block_pass

    super
  end
end

BuilderPrism.prepend(WithBlockNode)
