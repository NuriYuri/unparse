# All nodes like return, break, next, yield
class JumpNode < OverridableNode
end

module WithJumpNode
  JUMP_NODES = %i[return break next yield]
  def n(type, children, location)
    return JumpNode.new(type, children, { location: }) if JUMP_NODES.include?(type)

    super
  end
end

BuilderPrism.prepend(WithJumpNode)
