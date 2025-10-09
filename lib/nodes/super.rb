class SuperNode < OverridableNode
end

module WithSuperNode
  def n(type, children, location)
    return SuperNode.new(type, children, { location: }) if type == :super

    super
  end
end

BuilderPrism.prepend(WithSuperNode)
