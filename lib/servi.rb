require "scrivener"

class Servi
  attr :input

  def self.call(user_input, trusted_input)
    service = new(user_input)

    trusted_input.each do |key, value|
      service.send("#{key}=", value)
    end

    service.commit
  end

  def self.empty_result
    Servi::Result.new(:empty, {}, {}, Servi::Errors.new)
  end

  def initialize(input = {})
    @input = input
  end

  def commit
    form = self.class.const_get(:Input).new(input)

    if form.respond_to?(:context)
      form.context(self.validation_context)
    end

    if form.valid?
      build(form.attributes)
    else
      error(form.errors)
    end
  end

  # Things you may need when validating the input
  def validation_context
    {}
  end
  protected :validation_context

  def error(errors)
    Result.new(:error, @input, {}, Errors.new(errors))
  end
  protected :error

  def success(output = {})
    Result.new(:success, @input, output)
  end
  protected :success

  class Result
    attr :input
    attr :output
    attr :errors

    def initialize(status, input, output, errors = Hash.new { |hash, key| hash[key] = [] })
      @status = status
      @input = input
      @output = output
      @errors = errors
    end

    def ok?
      @status == :success
    end

    def [](key)
      @output.fetch(key)
    end
  end

  module InputWithValidationContext
    def context(context)
      @context = context
    end
  end

  class Errors
    def initialize(errors={})
      @errors = errors
    end

    def empty?
      @errors.empty?
    end

    def on(att, name)
      errors = lookup(att)
      error = errors && errors.include?(name)

      if block_given?
        yield if error
      else
        error
      end
    end

    def any?(att)
      errors = lookup(att)
      errors && errors.any?
    end

    def lookup(atts)
      Array(atts).inject(@errors) { |err, att| err && !err[att].empty? && err[att] }
    end

    def [](att)
      @errors[att]
    end
  end
end
