module Callable
  def self.extended(klass)
    klass.private_class_method(:new)
  end

  def call(...)
    new(...).call
  end
end
