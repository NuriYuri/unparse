class ClassSpace
  # TODO: make special cases for the non begin / kwbegin statements
  LOOP_INGESTIBLE_NODE = %i[kwbegin begin if when case while for resbody rescue ensure]

  def initialize
    @classes = { cbase: {} }
    @singleton_classes = { cbase: {} }
  end

  # Ingest a node to build the class space
  # @param node [Parser::AST::Node]
  def ingest(node, path = [:cbase])
    return unless node

    if node.is_a?(ClassNode) || node.is_a?(ModuleNode)
      new_path = base_name_and_get_next_path(node.name, path)
      insert_class_to(node, new_path, @classes)
      ingest(node.content, new_path)
    elsif node.is_a?(SingletonClassNode) && node.target&.type == :self
      insert_class_to(node, path, @singleton_classes)
    elsif LOOP_INGESTIBLE_NODE.include?(node.type)
      node.children.each { |n| ingest(n, path) }
    end
  end

  def as_node
    values = @classes[:cbase].values
    raise 'No classes or module to convert as node' if values.empty?
    return values[0][:self].as_node if values.size == 1

    children = values.map { |v| v[:self].as_node }
    return BeginNode.new(:begin, children, { location: children[0].location }).as_node
  end

  private

  # Base the class name and return the next path
  # @param name [ConstNode]
  # @param path [Array<Symbol>]
  # @return [Array<Symbol>]
  def base_name_and_get_next_path(name, path)
    new_path = name.base(path).path
    if new_path.size > 2 && new_path[1] == :Object
      new_path.delete_at(1)
    end
    return new_path
  end

  # Insert a class to the classes based on the path
  # @param klass [ClassNode | ModuleNode | SingletonClassNode]
  # @param path [Array<Symbol>] path to the class
  # @param h [Hash] @classes or @singleton_classes
  def insert_class_to(klass, path, h)
    path.each do |name|
      h = (h[name] ||= {})
    end
    h[:self] = h.has_key?(:self) ? h[:self].append(klass) : klass
  end
end
