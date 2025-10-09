class WhileNode < OverridableNode
end

module WithWhileNode
  def n(type, children, location)
    return WhileNode.new(type, children, { location: }) if type == :while

    super
  end
end

BuilderPrism.prepend(WithWhileNode)
