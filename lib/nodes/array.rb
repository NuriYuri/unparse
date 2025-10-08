class ArrayNode < OverridableNode
end

module WithArrayNode
  def n(type, children, location)
    return ArrayNode.new(type, children, { location: }) if type == :array

    super
  end
end

BuilderPrism.prepend(WithArrayNode)
