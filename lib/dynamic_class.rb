require 'dynamic_class/version'
require 'set'

module DynamicClass
  def self.new(&block)
    ::Class.new(::DynamicClass::Class).tap do |klass|
      klass.class_exec(&block) if block_given?
    end
  end

  class Class
    class << self
      def attributes
        @attributes ||= Set.new
      end

      # Always revert to original #to_h in case the parent class has already
      # redefined #to_h.
      def inherited(subclass)
        subclass.class_eval <<-RUBY
          def to_h
            {}
          end
        RUBY
      end

      def mutex
        @mutex ||= Mutex.new
      end

      def add_methods!(key)
        class_exec do
          mutex.synchronize do
            attr_writer key unless method_defined?("#{key}=")
            attr_reader key unless method_defined?("#{key}")
            attributes << key

            # I'm pretty sure this is safe, because attempting to add an attribute
            # that isn't a valid instance variable name will raise an error. Please
            # contact the maintainer if you find a situation where this could be a
            # security problem.
            #
            # The reason to use class_eval here is because, based on benchmarking,
            # this defines the fastest version of #to_h possible.
            class_eval <<-RUBY
              def to_h
                {
                  #{
                    attributes.map { |attribute|
                      "#{attribute.inspect} => #{attribute}"
                    }.join(",\n")
                  }
                }
              end
            RUBY
          end
        end
      end
    end

    def initialize(attributes = {})
      attributes.each_pair do |key, value|
        __send__(:"#{key}=", value)
      end
    end

    def to_h
      {}
    end

    def []=(key, value)
      key = key.to_sym
      instance_variable_set(:"@#{key}", value)
      self.class.add_methods!(key) unless self.class.attributes.include?(key)
    end

    def [](key)
      instance_variable_get(:"@#{key}")
    end

    def each_pair
      return to_enum(__method__) { self.class.attributes.size } unless block_given?
      to_h.each_pair do |key, value|
        yield key, value
      end
    end

    def method_missing(mid, *args)
      len = args.length
      if (mname = mid[/.*(?==\z)/m])
        if len != 1
          raise ArgumentError, "wrong number of arguments (#{len} for 1)", caller(1)
        end
        self[mname] = args.first
      elsif len == 0
        self[mid]
      else
        raise ArgumentError, "wrong number of arguments (#{len} for 0)", caller(1)
      end
    end

    def delete_field(key)
      instance_variable_set(:"@#{key}", nil)
    end

    def ==(other)
      other.is_a?(self.class) && to_h == other.to_h
    end

    def eql?(other)
      other.is_a?(self.class) && to_h.eql?(other.to_h)
    end

    def hash
      to_h.hash
    end
  end
end
