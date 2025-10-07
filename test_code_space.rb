require_relative 'lib/bootstrap'
require 'yaml'

$no_method_content = ARGV.include?('no_method_content')

space = CodeSpace.new

path = '/Volumes/mvme/projects/PokemonStudio/psdk-binaries/pokemonsdk/.release/scripts'
Dir["#{path}/*.rb"].each do |filename|
  base_name = File.basename(filename)
  puts "Processing #{base_name}"
  node, * = parse_with_comment(source_buffer(base_name, File.read(filename)))
  space.ingest_root(node)
end

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
  IVAR = $no_method_content ? %i[@name @arguments] : %i[@name @arguments @content]
  IVARO = IVAR.dup << :@overwrite
  def instance_variables
    @overwrite ? IVARO : IVAR
  end
end

class SingletonMethodNode
  IVAR = %i[@target @name @arguments @content]
  IVARO = IVAR.dup << :@overwrite
  def instance_variables
    @overwrite ? IVARO : IVAR
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

# Note about next section: it lists all the methods that are returning literals.
#   The returned list shows we cannot optimize method calls that returns literals.
#   In any case, those are not likely to be called a lot.
# all_classes = space.instance_variable_get(:@all_classes)
# all_classes.each do |c|
#   m = c.public_instance_methods.each_value.select { |m| m.is_value_method? }.concat(
#     c.private_instance_methods.each_value.select { |m| m.is_value_method? }
#   ).concat(
#     c.protected_instance_methods.each_value.select { |m| m.is_value_method? }
#   )
#   if m.size > 0
#     puts "Simple method values for #{c.path}"
#     puts m.map(&:name).join(', ')
#   end
# end

# File.write('code_space.yml', YAML.dump(space.instance_variable_get(:@all_classes_per_path).map { |k, v| [k.join('::'), v] }.to_h))
