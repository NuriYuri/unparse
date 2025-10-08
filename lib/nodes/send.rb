class SendNode < OverridableNode
  # @return [Parser::AST::Node]
  attr_reader :target
  # @return [Symbol]
  attr_reader :method_name
  # @return [Array<Parser::AST::Node>]
  attr_reader :arguments

  def initialize(type, children, props)
    @target, @method_name, *@arguments = children
    super
  end

  # @param type [Symbol]
  # @param children [Array<Parser::AST::Node | OverridableNode>]
  # @param props [Hash]
  # @return [Parser::AST::Node]
  def as_node(type = @type, children = nil, props = @props)
    super(type, children || [@target, @method_name, *@arguments], props)
  end

  def is_marker?(type)
    return @target == nil && @arguments.empty? && @method_name == type
  end

  PRIVATE_MARKER = SendNode.new(:send, [nil, :private], {})
  PUBLIC_MARKER = SendNode.new(:send, [nil, :public], {})
  PROTECTED_MARKER = SendNode.new(:send, [nil, :protected], {})
end

module WithSendNode
  def n(type, children, location)
    return SendNode.new(type, children, { location: }) if type == :send || type == :csend

    super
  end
end

BuilderPrism.prepend(WithSendNode)
