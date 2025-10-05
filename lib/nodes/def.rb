class MethodNode < OverridableNode
  # @return [Symbol]
  attr_reader :name
  # @return [Parser::AST::Node]
  attr_reader :arguments
  # @return [Parser::AST::Node]
  attr_reader :content

  def initialize(type, children, props)
    @name = children[0]
    @arguments = children[1]
    @content = children[2]
    super
  end

  # @param type [Symbol]
  # @param children [Array<Parser::AST::Node | OverridableNode>]
  # @param props [Hash]
  # @return [Parser::AST::Node]
  def as_node(type = @type, children = nil, props = @props)
    super(type, children || [@name, @arguments, @content], props)
  end

  # TODO: Define a overwrite method
end

module WithMethodNode
  def n(type, children, location)
    return MethodNode.new(type, children, { location: }) if type == :def

    super
  end
end

BuilderPrism.prepend(WithMethodNode)
