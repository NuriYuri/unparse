class RangeNode < OverridableNode
end

module WithRangeNode
  def n(type, children, location)
    return RangeNode.new(type, children, { location: }) if type == :erange || type == :irange

    super
  end
end

BuilderPrism.prepend(WithRangeNode)
