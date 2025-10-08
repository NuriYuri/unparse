class HashNode < OverridableNode
end
class PairNode < OverridableNode
end

module WithHashNode
  def n(type, children, location)
    return HashNode.new(type, children, { location: }) if type == :hash
    return PairNode.new(type, children, { location: }) if type == :pair

    super
  end
end

BuilderPrism.prepend(WithHashNode)
