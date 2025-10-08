class ArgsNode < OverridableNode
end
class OptArgNode < OverridableNode
end
class KwOptArgNode < OverridableNode
end

module WithArgsNode
  def n(type, children, location)
    return ArgsNode.new(type, children, { location: }) if type == :args
    return OptArgNode.new(type, children, { location: }) if type == :optarg
    return KwOptArgNode.new(type, children, { location: }) if type == :kwoptarg

    super
  end
end

BuilderPrism.prepend(WithArgsNode)
