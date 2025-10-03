class ModuleNode < OverridableNode
  # @type [ConstNode]
  attr_reader :name
  # @type [Parser::AST::Node]
  attr_reader :content

  def initialize(type, children, props)
    @name = children[0]
    @content = children[1]
    super
  end

  # @param type [Symbol]
  # @param children [Array<Parser::AST::Node | OverridableNode>]
  # @param props [Hash]
  # @return [Parser::AST::Node]
  def as_node(type = @type, children = nil, props = @props)
    super(type, children || [@name, @content], props)
  end

  # @param other_module [ModuleNode]
  # @return [self]
  def append(other_module)
    append_content(other_module.content)
    other_module.removed = true
    return self
  end

  prepend ClassNode::AppendContent
end

module WithModuleNode
  def n(type, children, location)
    return ModuleNode.new(type, children, { location: }) if type == :module

    super
  end
end

BuilderPrism.prepend(WithModuleNode)
