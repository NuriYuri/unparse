class ConstNode < OverridableNode
  # @type [Symbol]
  attr_reader :name
  # @type [Array<Symbol>]
  attr_reader :path

  def initialize(type, children, props)
    @name = children.last
    left = children[0]
    if left.nil?
      @path = [@name]  
    elsif left.is_a?(ConstNode)
      @path = left.path.dup
      @path.push(@name)
    elsif left.type == :cbase
      @path = [:cbase, @name]
    else
      @no_rebase = true
      @path = [@name] # <= Let's ignore this issue for very specific constant access
      # raise "Unexpected left part for constant: #{left}"
    end
    super
  end

  # Set the whole path to of the constant
  # @param parent_path [Array<Symbol>] path of the parent module/class
  # @return [self]
  def base(parent_path)
    raise "Cannot rebase dynamic constant #{self}" if @no_rebase
    return self if @path.first == :cbase # ::Const is already based

    @path.insert(0, *parent_path)
    # @children = [nil, @children.last]
    return self
  end
end

module WithConstNode
  def n(type, children, location)
    return ConstNode.new(type, children, { location: }) if type == :const

    super
  end
end

BuilderPrism.prepend(WithConstNode)
