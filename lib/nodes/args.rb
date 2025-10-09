class ArgsNode < OverridableNode
end
class OptArgNode < OverridableNode
end
class KwOptArgNode < OverridableNode
end
class ArgNode < OverridableNode
end
class ProcArg0Node < OverridableNode
end
class ObjCKWArgNode < OverridableNode
end


module WithArgsNode
  OTHER_ARGUMENTS = %i[arg restarg blockarg shadowarg kwarg kwrestarg]
  def n(type, children, location)
    return ArgsNode.new(type, children, { location: }) if type == :args
    return OptArgNode.new(type, children, { location: }) if type == :optarg
    return KwOptArgNode.new(type, children, { location: }) if type == :kwoptarg
    return ArgNode.new(type, children, { location: }) if OTHER_ARGUMENTS.include?(type)
    return ProcArg0Node.new(type, children, { location: }) if type == :procarg0
    return ObjCKWArgNode.new(type, children, { location: }) if type == :objc_kwarg

    super
  end
end

BuilderPrism.prepend(WithArgsNode)
