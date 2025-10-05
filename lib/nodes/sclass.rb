class SingletonClassNode < OverridableNode
  # @return [Parser::AST::Node]
  attr_reader :target
  # @return [Parser::AST::Node]
  attr_reader :content

  def initialize(type, children, props)
    @target = children[0]
    @content = children[1]
    super
  end

  # @param type [Symbol]
  # @param children [Array<Parser::AST::Node | OverridableNode>]
  # @param props [Hash]
  # @return [Parser::AST::Node]
  def as_node(type = @type, children = nil, props = @props)
    super(type, children || [@target, @content], props)
  end

  # @param other_class [SingletonClassNode]
  # @return [self]
  def append(other_class)
    append_content(other_class.content)
    other_class.removed = true
    return self
  end

  prepend ClassNode::AppendContent
end

module WithSingletonClassNode
  def n(type, children, location)
    return SingletonClassNode.new(type, children, { location: }) if type == :sclass

    super
  end
end

BuilderPrism.prepend(WithSingletonClassNode)
