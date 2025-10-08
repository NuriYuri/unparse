class CaseNode < OverridableNode
end
class WhenNode < OverridableNode
end

module WithCaseNode
  def n(type, children, location)
    return CaseNode.new(type, children, { location: }) if type == :case
    return WhenNode.new(type, children, { location: }) if type == :when

    super
  end
end

BuilderPrism.prepend(WithCaseNode)
