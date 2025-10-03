def source_buffer(filename, data)
  return Parser::Source::Buffer.new('test.rb', source: data)
end

# @parma source_buffer [Parser::Source::Buffer]
def parse_with_comment(source_buffer)
  Prism::Translation::Parser34.new(BuilderPrism.new).parse_with_comments(source_buffer)
end
