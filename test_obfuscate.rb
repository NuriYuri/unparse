require_relative 'lib/bootstrap'
require_relative 'lib/obfuscate'
require 'yaml'

$no_method_content = ARGV.include?('no_method_content')

space = CodeSpace.new

path = '/Volumes/mvme/projects/PokemonStudio/psdk-binaries/pokemonsdk/.release/optimized'
target_path = '/Volumes/mvme/projects/PokemonStudio/psdk-binaries/pokemonsdk/.release/obfuscated'
Dir.mkdir(target_path) unless Dir.exist?(target_path)

nodes = {}

Dir["#{path}/*.rb"].each do |filename|
  base_name = File.basename(filename)
  puts "Processing #{base_name}"
  node, * = parse_with_comment(source_buffer(base_name, File.read(filename)))
  space.ingest_root(node)
  nodes[base_name] = node
end

space.obfuscate
nodes.each do |filename, node|
  puts "Writing #{filename}"
  node = node.respond_to?(:as_node) ? node.as_node : node
  File.write(File.join(target_path, filename), Unparser.unparse(node))
end
