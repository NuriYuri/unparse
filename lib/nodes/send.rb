class SendNode < OverridableNode
  # @type [Parser::AST::Node]
  attr_reader :target
  # @type [Symbol]
  attr_reader :method_name
  # @type [Array<Parser::AST::Node>]
  attr_reader :arguments

  def initialize(type, children, props)
    @target, @method_name, *@arguments = children
    super
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
    return SendNode.new(type, children, { location: }) if type == :send

    super
  end
end

BuilderPrism.prepend(WithSendNode)
