class SingletonMethodNode < OverridableNode
  # @return [Parser::AST::Node]
  attr_reader :target
  # @return [Symbol]
  attr_reader :name
  # @return [Parser::AST::Node]
  attr_reader :arguments
  # @return [Parser::AST::Node]
  attr_reader :content
  # @return [MethodNode, nil]
  attr_accessor :overwrite

  def initialize(type, children, props)
    @target = children[0]
    @name = children[1]
    @arguments = children[2]
    @content = children[3]
    super
  end

  # @param type [Symbol]
  # @param children [Array<Parser::AST::Node | OverridableNode>]
  # @param props [Hash]
  # @return [Parser::AST::Node]
  def as_node(type = @type, children = nil, props = @props)
    super(type, children || [@target, @name, @arguments, @content], props)
  end
end

module WithSingletonMethodNode
  def n(type, children, location)
    return SingletonMethodNode.new(type, children, { location: }) if type == :defs

    super
  end
end

BuilderPrism.prepend(WithSingletonMethodNode)
SingletonMethodNode.include(ValueMethod)
