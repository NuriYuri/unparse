module B
  class D
    private

    def test
    end
    public

    def test2
    end

    def test3
    end

    class << self
      def d_self
      end
    end
  end

  class E
    class F
    end
  end

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

module A
  class B
    class C
    end
  end
end

class ::Object::True
end

class Object
  A = 5
end
