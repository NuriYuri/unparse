class Test
  def initialize(values, kw: 0)
    @values = values
    @kw = kw
  end

  # Updates the shit
  # Second line
  def update
    @values.map { |f,|
      f.to_s
    }.select { |f,|
      f.size > 0
    }
  end

  def dispose(reason, &on_dispose)
    @values.each(&on_dispose)
    @kw * reason
  end

  def print_kw(arg)
    print(@kw, arg)
  end
end

module Test2
  def update
    super.compact
  end

  def dispose
    super(...)
    print("disposed", __FILE__)
  end

  def print_kw(arg)
    super
    print(arg * 2)
  rescue Exception => e
    print(e)
  end
end
Test.prepend(Test2)
