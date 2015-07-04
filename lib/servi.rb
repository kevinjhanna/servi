require_relative "servi/validations"

class Servi
  include Servi::Validations

  attr_reader :errors

  def self.call(params, trusted = {})
    merged = params.dup

    trusted.each do |key, value|
      merged[key.to_s] = value
    end

    service = new(merged)

    service.validate

    if service.errors.empty?
      service.build(service.clean)
    else
      service.error(service.errors)
    end
  end

  def initialize(params)
    @params = params
    @errors = Hash.new { |hash, key| hash[key] = [] }
  end

  def get(attr)
    @params[attr.to_s]
  end

  def error(errors)
    Result.new(:error, @params, {}, errors)
  end

  def success(output = {})
    Result.new(:success, @params, output)
  end

  class Result
    attr :output
    attr :params
    attr :errors

    def initialize(status, params, output, errors = Hash.new { |hash, key| hash[key] = [] })
      @status = status
      @params = params
      @output = output
      @errors = errors
    end

    def self.unbounded
      Result.new(:unbound, {}, {})
    end

    def ok?
      @status == :success
    end

    def [](key)
      @output.fetch(key)
    end
  end
end
