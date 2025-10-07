class MethodNode < OverridableNode
  # @return [Symbol]
  attr_reader :name
  # @return [Parser::AST::Node]
  attr_reader :arguments
  # @return [Parser::AST::Node]
  attr_reader :content
  # @return [MethodNode, nil]
  attr_accessor :overwrite

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
end

module ValueMethod
  SIMPLE_LITERALS = %i[int float sym str]

  def is_value_method?
    return @overwrite.is_value_method? if @overwrite
    return false if @arguments&.children&.size > 0
    return false unless @content
    return false if @content.type == :return && @content.children.size != 1

    node = @content.type == :return ? @content.children[0] : @content

    return false if node.is_a?(BeginNode)
    return true if SIMPLE_LITERALS.include?(node.type)
    return false if node.type != :array
    # Check array
    return node.children.all? { |n| SIMPLE_LITERALS.include?(n.type) }
  end
end

module WithMethodNode
  def n(type, children, location)
    return MethodNode.new(type, children, { location: }) if type == :def

    super
  end
end

BuilderPrism.prepend(WithMethodNode)
MethodNode.include(ValueMethod)
