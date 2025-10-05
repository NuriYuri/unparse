require_relative 'lib/bootstrap'
require 'yaml'

filepath = '/Volumes/mvme/projects/PokemonStudio/psdk-binaries/pokemonsdk/.release/scripts/0_Dependencies.rb'
node, * = parse_with_comment(source_buffer('test.rb', File.read(filepath)))

space = CodeSpace.new
space.ingest_root(node)

class Parser::Source::Range
  def instance_variable_get(ivar)
    return 'anonymous' if ivar == :@source_buffer

    super
  end
end

class CodeSpace::CodeSpaceClass
  def instance_variable_get(ivar)
    return '<space>' if ivar == :@space

    super
  end
end

class MethodNode
  IVAR = %i[@name @arguments @content]
  def instance_variables
    IVAR
  end
end

class SingletonMethodNode
  IVAR = %i[@target @name @arguments @content]
  def instance_variables
    IVAR
  end
end

class SendNode
  IVAR = %i[@target @method_name @arguments]
  def instance_variables
    IVAR
  end
end

class ClassNode
  IVAR = %i[@name @super_class]
  def instance_variables
    IVAR
  end
end

class ModuleNode
  IVAR = %i[@name @super_class]
  def instance_variables
    IVAR
  end
end

class SingletonClassNode
  IVAR = %i[@target]
  def instance_variables
    IVAR
  end
end

class ConstNode
  IVAR = %i[@name @path]
  def instance_variables
    IVAR
  end
end

class Parser::AST::Node
  IVAR = %i[@type @children]
  def instance_variables
    IVAR
  end
end

class Psych::Visitors::YAMLTree
  def binary?(o)
    (o.encoding == Encoding::ASCII_8BIT && !o.ascii_only?) || o.include?("\x00")
  end
end

File.write('code_space.yml', YAML.dump(space.instance_variable_get(:@all_classes_per_path).map { |k, v| [k.join('::'), v] }.to_h))
