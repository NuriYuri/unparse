module B
  class D
    private
    def test
    end
  end
end

module A
  class B
    class C

    end
  end
end

module B
  class D
    def test2
    end
  end
  class E
    class F

    end
  end
end

class ::Object::True

end

class B::D
  def test3
  end

  class << self
    def d_self
    end
  end
end

module B
  class << self
    def method
    end
  end

  def self.method2
  end

  # B::Object instead of ::Object
  class Object
  end
end

class Object
  A = 5
end
