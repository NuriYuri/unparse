def source_buffer(filename, data)
  return Parser::Source::Buffer.new('test.rb', source: data)
end

PARSER_CLASS = Class.new(Prism::Translation::Parser34) do
  def declare_local_variable(local_variable)
    (@local_variables ||= Set.new) << local_variable
  end

  def prism_options
    super.merge(scopes: [@local_variables.to_a])
  end
end

# @parma source_buffer [Parser::Source::Buffer]
def parse_with_comment(source_buffer)
  PARSER_CLASS.new(BuilderPrism.new).parse_with_comments(source_buffer)
end
