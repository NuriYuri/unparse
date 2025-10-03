class ClassNode < OverridableNode
  # @type [ConstNode]
  attr_reader :name
  # @type [ConstNode, nil]
  attr_reader :super_class
  # @type [Parser::AST::Node]
  attr_reader :content

  # @param type [Symbol]
  # @param children [Array<Parser::AST::Node | OverridableNode>]
  # @param props [Hash]
  def initialize(type, children, props)
    @name = children[0]
    @super_class = children[1]
    @content = children[2]
    super
  end

  # @param type [Symbol]
  # @param children [Array<Parser::AST::Node | OverridableNode>]
  # @param props [Hash]
  # @return [Parser::AST::Node]
  def as_node(type = @type, children = nil, props = @props)
    super(type, children || [@name, @super_class, @content], props)
  end

  # @param other_class [ClassNode]
  # @return [self]
  def append(other_class)
    @super_class ||= other_class.super_class
    append_content(other_class.content)
    other_class.removed = true
    return self
  end

  module AppendContent
    private

    # @param other_content [Parser::AST::Node | OverridableNode]
    def append_content(other_content)
      unless @content.is_a?(BeginNode)
        props = @content.is_a?(OverridableNode) ? @content.props : { location: @content.location }
        @content = BeginNode.new(:begin, [@content], props)
      end
      unless other_content.is_a?(BeginNode)
        props = other_content.is_a?(OverridableNode) ? other_content.props : { location: other_content.location }
        other_content = BeginNode.new(:begin, [other_content], props)
      end
      last_private_index = @content.children.rindex { |e| e.is_a?(SendNode) && (e.is_marker?(:private) || e.is_marker?(:protected)) }
      
      if last_private_index
        last_public_index = @content.children.rindex { |e| e.is_a?(SendNode) && e.is_marker?(:public) }
        unless last_public_index
          @content.push(SendNode::PUBLIC_MARKER)
        else
          @content.push(SendNode::PUBLIC_MARKER) if last_private_index > last_public_index
        end
      end
      @content.concat(other_content)
    end
  end

  prepend AppendContent
end

module WithClassNode
  def n(type, children, location)
    return ClassNode.new(type, children, { location: }) if type == :class

    super
  end
end

BuilderPrism.prepend(WithClassNode)
