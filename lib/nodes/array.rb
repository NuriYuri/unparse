class ArrayNode < OverridableNode
end
class SplatNode < OverridableNode
end

module WithArrayNode
  def n(type, children, location)
    return ArrayNode.new(type, children, { location: }) if type == :array
    return SplatNode.new(type, children, { location: }) if type == :splat

    super
  end
end

BuilderPrism.prepend(WithArrayNode)
