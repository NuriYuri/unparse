class OverridableNode < Parser::AST::Node
  EMPTY = [].freeze
  # @return [Symbol]
  attr_reader :type
  # @return [Array<Parser::AST::Node | OverridableNode>]
  attr_reader :children
  # @return [Hash]
  attr_reader :props
  # @return [Boolean]
  attr_accessor :removed

  # @param type [Symbol]
  # @param children [Array<Parser::AST::Node | OverridableNode>]
  # @param props [Hash]
  def initialize(type, children, props)
    @props = props
    @removed = false
    super
    @type = type
    # @type [Array<Parser::AST::Node | OverridableNode>]
    @children = children
  end

  def freeze
    return self
  end

  # @param type [Symbol]
  # @param children [Array<Parser::AST::Node | OverridableNode>]
  # @param props [Hash]
  # @return [Parser::AST::Node]
  def as_node(type = @type, children = @children, props = @props)
    return EMPTY if @removed
    return Parser::AST::Node.new(type, map_children(children), props)
  end

  # Fix for unparser
  def instance_of?(*args)
    return true if args[0] == Parser::AST::Node
  end

  # Fix for unparser
  def class
    return Parser::AST::Node
  end

  private

  # @param children [Array<Parser::AST::Node | OverridableNode>]
  # @return [Array<Parser::AST::Node>]
  def map_children(children)
    return children.flat_map(&method(:map_child))
  end

  # @param child [Parser::AST::Node | OverridableNode]
  # @return Parser::AST::Node
  def map_child(child)
    return child.is_a?(OverridableNode) ? child.as_node : child
  end
end
