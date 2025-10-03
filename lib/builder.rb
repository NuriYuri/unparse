# Use a module to not duplicate the implementation
module BuilderExtensions
  def self.inherited(base)
    # Always emit the most modern format available
    base.modernize
  end

  def initialize(...)
    super(...)
    self.emit_file_line_as_literals = false if defined?(:emit_file_line_as_literals=)
  end
end

class BuilderPrism < Prism::Translation::Parser::Builder
  include BuilderExtensions

  # def n(type, children, location)
  #   case type
  #   when :begin
  #     return BeginNode.new(type, children, {location:})
  #   end
  #   return Parser::AST::Node.new(type, children, {location:})
  # end
end
