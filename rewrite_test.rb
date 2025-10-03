require 'unparser'
require 'prism'
require 'parser'

$classes = {}
$modules = {}

node = Prism::Translation::Parser34.parse(readlines.join)
$super_forward_arg = Prism::Translation::Parser34.parse('def test(...);super(...);end').children[2]

def handle_prepend(klass, mod)
  puts "Prepend #{mod} into #{klass}"
  class_node = $classes[klass]
  module_node = $modules[mod]
  puts "Class found: #{class_node != nil}"
  puts "Module found: #{module_node != nil}"
  class_methods = get_methods(class_node)
  module_methods = get_methods(module_node)
  module_methods.each do |name, method_node|
    class_method_node = class_methods[name]
    method_node = fix_method_arguments(method_node, class_method_node)
    class_methods[name] = overwrite_super(method_node, class_method_node)
  end
  children = class_node.children.dup
  children[2] = to_begin_or_self(class_methods.map { |name, meth| meth })
  $classes[klass] = class_node.updated(nil, children)
end

# @param method_node [Parser::AST::Node]
# @param class_method_node [Parser::AST::Node]
# @return [Parser::AST::Node]
def fix_method_arguments(method_node, class_method_node)
  return method_node if method_node.children[1] == class_method_node.children[1]

  children = method_node.children.dup
  children[1] = class_method_node.children[1]
  return method_node.updated(nil, children, nil)
end

# @param method_node [Parser::AST::Node]
# @param class_method_node [Parser::AST::Node]
# @return [Parser::AST::Node]
def overwrite_super(method_node, class_method_node)
  children = method_node.children.dup
  child = children[2]
  if child.type == :begin
    children[2] = overwrite_super_in_begin(child, class_method_node)
  elsif child.type == :send
    children[2] = overwrite_send_super(child, class_method_node) if child.children[0]&.type == :zsuper
  elsif child == $super_forward_arg || child.type == :zsuper
    children[2] = class_method_node.children[2]
  else
    puts "Unhandled node: #{child}"
  end
  return method_node.updated(nil, children, nil)
end

# @param node [Parser::AST::Node]
# @param class_method_node [Parser::AST::Node]
# @return [Parser::AST::Node]
def overwrite_super_in_begin(node, class_method_node)
  children = node.children.flat_map do |child|
    if child.type == :begin
      next overwrite_super_in_begin(child, class_method_node)
    elsif child.type == :send
      next overwrite_send_super(child, class_method_node) if child.children[0]&.type == :zsuper
      next child
    elsif child == $super_forward_arg || child.type == :zsuper
      new_node = class_method_node.children[2]
      # We should normally avoid to unroll begin node, I do because it looks nicer right now
      next new_node.type == :begin ? new_node.children : new_node
    else
      puts "Unhandled node: #{child}"
    end
  end

  return node.updated(nil, children, nil)
end

# @param node [Parser::AST::Node]
# @param class_method_node [Parser::AST::Node]
# @return [Parser::AST::Node]
def overwrite_send_super(node, class_method_node)
  children = node.children.dup
  children[0] = to_kwbegin(class_method_node.children[2])

  return node.updated(nil, children, nil)
end

# @param node [Parser::AST::Node]
def to_kwbegin(node)
  if node.type == :begin
    return node.updated(:kwbegin)
  else
    return Parser::AST::Node.new(:kwbegin, [node])
  end
end

# @param node [Parser::AST::Node]
def get_methods(node)
  method = node.type == :class ? node.children[2] : node.children[1]
  if method.type == :def
    return { children[0].children[0] => children[0] }
  end

  return method.children.map { |child| [child.children[0], child] }.to_h
end

# @param node [Array<Parser::AST::Node>]
def to_begin_or_self(nodes)
  return nodes[0] if nodes.size == 1

  return Parser::AST::Node.new(:begin, nodes)
end

node.children.each do |child|
  if child.type == :class
    $classes[child.children[0]] = child
  elsif child.type == :module
    $modules[child.children[0]] = child
  elsif child.type == :send && child.children[1] == :prepend
    handle_prepend(child.children[0], child.children[2])
  else
    puts "Unknown node handling: #{node.type}"
  end
end

new_node = to_begin_or_self($classes.map { |sym, klass| klass })
File.write('output-new-node.txt', new_node.to_s)
unparsed = Unparser.unparse(new_node)
File.write('test_output.rb', unparsed)