class DstrNode < OverridableNode
end
class DsymNode < OverridableNode
end

module WithDstrNode
  def n(type, children, location)
    return DstrNode.new(type, children, { location: }) if type == :dstr
    return DsymNode.new(type, children, { location: }) if type == :dsym

    super
  end
end

BuilderPrism.prepend(WithDstrNode)
