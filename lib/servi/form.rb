class Servi
  class Form
    def self.empty
      new(Servi::Result.new(:unbound, {}, {}))
    end

    def self.from(attrs)
      form = self.empty
      form.fill(attrs)
      form
    end

    def initialize(result)
      @result = result
    end

    def params
      @result.params
    end

    def errors
      Errors.new(@result.errors)
    end
  end

  class Errors
    def initialize(errors)
      @errors = errors
    end

    def empty?
      @errors.empty?
    end

    def on(att, name)
      @errors[att].include?(name)
    end

    def [](key)
      @errors[key]
    end

    def each
      @errors.each do |att, names|
        names.each do |name|
          yield([att, name])
        end
      end
    end
  end
end
