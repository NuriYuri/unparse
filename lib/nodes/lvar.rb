class LvarNode < OverridableNode
  # @return [Symbol]
  attr_reader :name

  def initialize(type, children, props)
    @name, * = children
    super
  end

  # @param type [Symbol]
  # @param children [Array<Parser::AST::Node | OverridableNode>]
  # @param props [Hash]
  # @return [Parser::AST::Node]
  def as_node(type = @type, children = nil, props = @props)
    super(type, children || [@name], props)
  end
end

module WithLvarNode
  def n(type, children, location)
    return LvarNode.new(type, children, { location: }) if type == :lvar

    super
  end

  def updated(type = nil, children = nil, props = nil)
    return LvarNode.new(type, children || @children, props || { location: @location }) if type == :lvar
    super
  end
end

Parser::AST::Node.prepend(WithLvarNode)
BuilderPrism.prepend(WithLvarNode)
