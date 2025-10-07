class CodeSpace
  def initialize
    @all_classes = []
    @all_classes_per_path = {}
  end

  # @param path [Array<Symbol>]
  # @return [CodeSpaceClass]
  def get_class(path)
    klass = @all_classes_per_path[path]
    unless klass
      STDERR.puts "Cannot locate class for path #{path.join('::')}" 
      klass = @all_classes_per_path[path] = CodeSpaceClass.new(path, path[0...], nil, self)
    end

    return klass
  end

  # @param path [Array<Symbol>]
  # @param klass [CodeSpaceClass]
  def register(path, klass)
    @all_classes_per_path[path] = klass
    @all_classes << klass
    return self
  end

  # @param node [ClassNode | ModuleNode | SingletonClassNode]
  # @param path [Array<Symbol>]
  # @return [CodeSpaceClass]
  def ingest(node, path)
    if node.is_a?(SingletonClassNode)
      return ingest_init([*path, :self], path, node) if node.target&.type == :self
      raise "Unsupported SingletonClassNode with target: #{node.target}"
    end
    node.name.base(path)
    return ingest_init(node.name.path, path, node)
  end

  # @param path [Array<Symbol>]
  # @param parent_path [Array<Symbol>]
  # @param node [ClassNode | ModuleNode | SingletonClassNode]
  def ingest_init(path, parent_path, node)
    if klass = @all_classes_per_path[path]
      klass.ingest(node)
      return klass
    end
    return CodeSpaceClass.new(path, parent_path, node, self)
  end

  # @param node [Parser::AST::Node]
  # @param path [Array<Symbol>]
  def ingest_root(node, path = [:cbase])
    if node.is_a?(BeginNode)
      node.children.each do |c|
        ingest_root(c, path)
      end
    elsif node.is_a?(SingletonClassNode) || node.is_a?(ClassNode) || node.is_a?(ModuleNode)
      ingest(node, path)
    end
  end

  class CodeSpaceClass
    # @return [Array<Symbol>]
    attr_reader :path
    # @return [Array<Symbol>, nil]
    attr_reader :parent
    # @return [Array<Symbol>, nil]
    attr_reader :super_class
    # @return [Hash{ Symbol => Parser::AST::Node }]
    attr_reader :constants
    # @return [Hash{ Symbol => MethodNode }]
    attr_reader :public_instance_methods
    # @return [Hash{ Symbol => MethodNode }]
    attr_reader :private_instance_methods
    # @return [Hash{ Symbol => MethodNode }]
    attr_reader :protected_instance_methods
    # @return [Hash{ Symbol => MethodNode }]
    attr_reader :public_methods
    # @return [Hash{ Symbol => MethodNode }]
    attr_reader :private_methods
    # @return [Hash{ Symbol => MethodNode }]
    attr_reader :protected_methods
    # @return [Array<Array<Symbol>>]
    attr_reader :includes
    # @return [Array<Array<Symbol>>]
    attr_reader :prepends
    # @return [Array<Symbol>]
    attr_reader :reader_attributes
    # @return [Array<Symbol>]
    attr_reader :writer_attributes
    # @return [Array<Symbol>]
    attr_reader :accessor_attributes

    # @param path [Array<Symbol>]
    # @param parent_path [Array<Symbol>]
    # @parma node [ClassNode | ModuleNode | SingletonClassNode]
    # @param space [CodeSpace]
    def initialize(path, parent_path, node, space)
      @space = space
      @path = path
      @parent = parent_path
      @super_class = compute_super_class(node, parent_path)
      @constants = {}
      @public_instance_methods = {}
      @private_instance_methods = {}
      @protected_instance_methods = {}
      @public_methods = {}
      @private_methods = {}
      @protected_methods = {}
      @includes = []
      @prepends = []
      @reader_attributes = []
      @writer_attributes = []
      @accessor_attributes = []
      @current_visibility = :public
      space.register(path, self)
      ingest(node)
    end

    # @param node [ClassNode | ModuleNode | SingletonClassNode]
    def ingest(node)
      return unless node

      # @type [Parser::AST::Node, nil]
      content = node.content
      return unless content

      if content.is_a?(BeginNode)
        ingest_begin_node(content)
      else
        ingest_non_begin_node(content)
      end
    end

    # @param node [BeginNode]
    def ingest_begin_node(node)
      node.children.each do |n|
        if n.is_a?(BeginNode)
          ingest_begin_node(n)
        else
          ingest_non_begin_node(n)
        end
      end
    end

    # @param node [Parser::AST::Node]
    def ingest_non_begin_node(node)
      if node.is_a?(ClassNode) || node.is_a?(ModuleNode)
        data = @space.ingest(node, @path)
        name = data.path.last
        @constants[name] = data
      elsif node.is_a?(SingletonClassNode)
        data = @space.ingest(node, @path)
        @public_methods.merge!(data.public_instance_methods)
        @private_methods.merge!(data.private_instance_methods)
        @protected_methods.merge!(data.protected_instance_methods)
      elsif node.is_a?(MethodNode)
        case @current_visibility
        when :public then @public_instance_methods[node.name] = node
        when :private then @private_instance_methods[node.name] = node
        when :protected then @protected_instance_methods[node.name] = node
        end
      elsif node.is_a?(SingletonMethodNode)
        case @current_visibility
        when :public then @public_methods[node.name] = node
        when :private then @private_methods[node.name] = node
        when :protected then @protected_methods[node.name] = node
        end
      elsif node.type == :alias
        ingest_alias(node)
      elsif node.is_a?(SendNode)
        ingest_send(node)
      else
        ingest_other_node(node)
      end
    end

    # @param node [Parser::AST::Node]
    def ingest_other_node(node)
      case node.type
      when :casgn
        return if node.children[0]

        @constants[node.children[1]] = node.children[2]
      end
    end

    # @param node [SendNode]
    def ingest_send(node)
      return if node.target != nil # <= Does not concern us

      handle_send(node.method_name, node.arguments)
    end

    # @param method_name [Symbol]
    # @param arguments [Array<Parser::AST::Node]
    def handle_send(method_name, arguments)
      arg0 = arguments[0]
      case method_name
      when :prepend
        const = search_const(arg0.path) if arg0.is_a?(ConstNode) && arguments.size == 1
        @prepends << const.path if const.is_a?(CodeSpaceClass)
      when :include
        const = search_const(arg0.path) if arg0.is_a?(ConstNode) && arguments.size == 1
        @includes << const.path if const.is_a?(CodeSpaceClass)
      when :attr_reader
        @reader_attributes.concat(arguments.map { |v| v.children[0] })
      when :attr_writer
        @writer_attributes.concat(arguments.map { |v| v.children[0] })
      when :attr_accessor
        @accessor_attributes.concat(arguments.map { |v| v.children[0] })
      when :remove_const
        STDERR.puts "Went through remove_const for #{@path} => #{arguments}"
        # TODO
      when :public
        if arg0
          if arg0.is_a?(MethodNode)
            @public_instance_methods[arg0.name] = arg0
          elsif arg0.is_a?(SingletonMethodNode)
            @public_methods[arg0.name] = arg0
          end
        else
          @current_visibility = :public
        end
      when :private
        if arg0
          if arg0.is_a?(MethodNode)
            @private_instance_methods[arg0.name] = arg0
          elsif arg0.is_a?(SingletonMethodNode)
            @private_methods[arg0.name] = arg0
          end
        else
          @current_visibility = :private
        end
      when :protected
        if arg0
          if arg0.is_a?(MethodNode)
            @protected_instance_methods[arg0.name] = arg0
          elsif arg0.is_a?(SingletonMethodNode)
            @protected_methods[arg0.name] = arg0
          end
        else
          @current_visibility = :protected
        end
      end
    end

    # @param node [Parser::AST::Node]
    def ingest_alias(node)
      to, from, * = node.children
      return unless from.type == :sym && to.type == :sym

      node = search_method(from.children[0])
      return unless node

      name = to.children[0]
      # We're looking into instance methods of self to avoid undesired overwrite of parent or mixin methods
      existing_method = @public_instance_methods[name] || @private_instance_methods[name] || @protected_instance_methods[name] 
      return existing_method.overwrite = node if existing_method

      case @current_visibility
      when :public then @public_instance_methods[name] = node.dup
      when :private then @private_instance_methods[name] = node.dup
      when :protected then @protected_instance_methods[name] = node.dup
      end
    end

    # @param name [Symbol]
    # @return [MethodNode | nil]
    def search_method(name)
      @prepends.reverse_each do |path|
        klass = @space.get_class(path)

        node = klass.public_instance_methods[name] || klass.private_instance_methods[name] || klass.protected_instance_methods[name]
        return node if node
      end

      node = @public_instance_methods[name] || @private_instance_methods[name] || @protected_instance_methods[name]
      return node if node

      @includes.reverse_each do |path|
        klass = @space.get_class(path)

        node = klass.public_instance_methods[name] || klass.private_instance_methods[name] || klass.protected_instance_methods[name]
        return node if node
      end

      return nil unless @super_class

      return @space.get_class(@super_class).search_method(name)
    end

    # @param path [Array<Symbol>]
    # @return [CodeSpaceClass | Parser::AST::Node]
    def search_const(path)
      return @space.get_class(path) if path[0] == :cbase

      if path.size == 1
        if constant = @constants[path[0]]
          return constant if constant.is_a?(CodeSpaceClass)
          return search_const(constant.path) if constant.is_a?(ConstNode)
          return constant
        end
        @prepends.reverse_each do |path|
          klass = @space.get_class(path)

          constant = klass.search_const(path)
          return constant if constant
        end
        @includes.reverse_each do |path|
          klass = @space.get_class(path)

          constant = klass.search_const(path)
          return constant if constant
        end
        return @space.get_class(@super_class).search_const(path) if @super_class
      else
        name, *rest = path
        constant = search_const([name])
        return nil unless constant

        return constant.search_const(rest) if constant.is_a?(CodeSpaceClass)
      end

      return nil
    end

    private

    # @param node [Parser::AST::Node | nil]
    # @param parent_path [Array<Symbol>]
    # @return [Array<Symbol> | nil]
    def compute_super_class(node, parent_path)
      return nil unless node
      return nil unless node.is_a?(ClassNode)
      return nil unless node.super_class
      
      if node.super_class.is_a?(ConstNode)
        return node.super_class.base(parent_path).path
      elsif node.super_class.type == :self
        return parent_path
      end

      return nil
    end
  end
end
