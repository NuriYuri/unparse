class ForNode < OverridableNode
end

module WithForNode
  def n(type, children, location)
    return ForNode.new(type, children, { location: }) if type == :for

    super
  end
end

BuilderPrism.prepend(WithForNode)
