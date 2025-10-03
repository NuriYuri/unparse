require_relative 'lib/bootstrap'

node, comments = parse_with_comment(source_buffer('test.rb',readlines.join))

class_space = ClassSpace.new
class_space.ingest(node)

File.write('ingestion_output.rb',  Unparser.unparse(class_space.as_node, comments: comments))

class Parser::AST::Node
  def inspect
    return "<node:#{type}:#{name}##{__id__}>" if respond_to?(:name)
    return "<node:#{type}##{__id__}>"
  end
end
class ConstNode
  def to_s
    return @name.to_s
  end
end
File.write('ingestion.txt', class_space.inspect)