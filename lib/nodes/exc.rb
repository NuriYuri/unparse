# I'm doing this generic node because it's not currently worth trying to distinguish each exception related nodes
class ExcNode < OverridableNode
end

module WithExcNode
  ALL_EXC_NODES = %i[rescue kwbegin resbody ensure]
  def n(type, children, location)
    return ExcNode.new(type, children, { location: }) if ALL_EXC_NODES.include?(type)

    super
  end
end

BuilderPrism.prepend(WithExcNode)
