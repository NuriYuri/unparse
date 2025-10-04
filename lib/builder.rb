class BuilderPrism < Prism::Translation::Parser::Builder
  modernize

  # mutant:disable
  def initialize
    super

    self.emit_file_line_as_literals = false
  end
end
