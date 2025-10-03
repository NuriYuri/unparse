require_relative 'lib/bootstrap'

node, comments = parse_with_comment(source_buffer('test.rb', File.read('mocks/broken_cases.rb')))
puts Unparser.unparse(node, comments: comments)
