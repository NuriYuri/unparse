class WhileNode < OverridableNode
end
class UntilNode < OverridableNode
end

module WithWhileNode
  def n(type, children, location)
    return WhileNode.new(type, children, { location: }) if type == :while
    return UntilNode.new(type, children, { location: }) if type == :until

    super
  end
end

BuilderPrism.prepend(WithWhileNode)
