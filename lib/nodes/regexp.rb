class RegexpNode < OverridableNode
end

module WithRegexpNode
  def n(type, children, location)
    return RegexpNode.new(type, children, { location: }) if type == :regexp

    super
  end
end

BuilderPrism.prepend(WithRegexpNode)
