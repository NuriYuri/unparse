require_relative 'lib/bootstrap'

node, comments = parse_with_comment(source_buffer('test.rb',readlines.join))
File.write('output.txt', node.inspect)
