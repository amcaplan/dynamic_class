require "dynamic_class/version"
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

      def inspect
        super.insert(2, 'DynamicClass::')
      end

      # Always revert to original #to_h in case the parent class has already
      # redefined #to_h.
      def inherited(subclass)
        subclass.class_eval <<-RUBY
          def to_h
            {}.tap do |hash|
              each_pair do |key, value|
                hash[key] = value
              end
            end
          end
        RUBY
      end
    end

    def initialize(attributes = {})
      attributes.each_pair do |key, value|
        send(:[]=, key, value)
      end
    end

    def to_h
      {}.tap do |hash|
        each_pair do |key, value|
          hash[key] = value
        end
      end
    end

    def []=(key, value)
      instance_variable_set(:"@#{key}", value)
      key = key.to_sym
      add_methods!(key) unless self.class.attributes.include?(key)
    end

    def [](key)
      instance_variable_get(:"@#{key}")
    end

    def each_pair
      return to_enum(__method__) { self.class.attributes.size } unless block_given?
      self.class.attributes.map do |attribute|
        yield(attribute, instance_variable_get(:"@#{attribute}"))
      end
    end

    def method_missing(mid, *args)
      len = args.length
      if mname = mid[/.*(?==\z)/m]
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

    def inspect
      inspecting_ids = (Thread.current[:__inspecting_dynamic_class__] ||= [])
      str = "#<DynamicClass::Class"
      if inspecting_ids.include?(object_id)
        return str << ' ...>'
      else
        begin
          inspecting_ids.push(object_id)
          attributes = self.class.attributes.map { |attribute|
            "#{attribute}=#{self.send(attribute).inspect}"
          }.join(', ')
          return str << '>' if attributes.empty?
          return str << ' ' << attributes << '>'
        ensure
          inspecting_ids.pop
        end
      end
    end

    def delete_field(key)
      self[key] = nil
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

    private
    def add_methods!(key)
      self.class.send(:attr_accessor, key)
      self.class.attributes << key
      self.class.class_eval <<-RUBY
        def to_h
          {
            #{
              self.class.attributes.map { |attribute|
                "#{attribute.inspect} => #{attribute}"
              }.join(",\n")
            }
          }
        end
      RUBY
    end
  end
end
