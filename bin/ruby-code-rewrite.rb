# Before use:
#  1. have Ruby 3.4+
#  2. Install the gem unparser
# Usage:
#   - ruby ruby-code-rewrite.rb filename documentation_with_method_body
#   - ruby ruby-code-rewrite.rb filename documentation

MODES = {
  "documentation_with_method_body" => :base,
  "documentation" => :erase_method_body
}

mode = MODES[ARGV[1]]
filename = ARGV[0]

raise 'Expected two arguments: filename mode' if ARGV.size != 2
raise "Invalid mode, expected: #{MODES.keys.join(',')}" unless mode

require_relative '../lib/bootstrap'

module NoBody
  def initialize(...)
    super(...)
    @content = nil
  end
end

MethodNode.prepend(NoBody) if mode == :erase_method_body

node, comments = parse_with_comment(source_buffer(filename, File.binread(filename).force_encoding(Encoding::UTF_8)))

class_space = ClassSpace.new
class_space.ingest(node)

STDOUT.write(Unparser.unparse(class_space.rewrite_node(node), comments: comments))
STDOUT.flush

exit(0)
