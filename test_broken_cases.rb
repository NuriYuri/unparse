require_relative 'lib/bootstrap'

node, comments = parse_with_comment(source_buffer('test.rb', File.read('mocks/broken_cases.rb')))

class_space = ClassSpace.new
class_space.ingest(node)

puts Unparser.unparse(class_space.rewrite_node(node), comments: comments)
