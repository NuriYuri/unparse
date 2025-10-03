require_relative 'lib/bootstrap'

node_class = Parser::AST::Node

class BeginNode < node_class
  def initialize(type, children, props)
    super
    puts "Initialized begin node with #{children.size} childrens"
  end
end

class BuilderPrism
  def n(type, children, location)
    case type
    when :begin
      return BeginNode.new(type, children, {location:})
    end
    return Parser::AST::Node.new(type, children, {location:})
  end
end

buff = source_buffer('test.rb', readlines.join)
node, comments = parse_with_comment(buff)
# File.write('output.txt', node.inspect)
# File.write('test_output.rb', Unparser.unparse(node, comments: comments))
