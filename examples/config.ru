require "cuba"
require "cuba/render"
require "erb"

require File.expand_path("../lib/servi", File.dirname(__FILE__))

module Services
  class Movie
  end
end

Movie = Struct.new(:id, :title, :body)

class MovieValidation < Servi::Input
  attr_accessor :title
  attr_accessor :body

  def validate
    assert_present :title
    assert_present :body
  end
end

class Services::Movie::Create < Servi
  def build(input)
    # You would do
    # movie = Movie.create(input)

    movie = Movie.new(1, input[:title], input[:body])
    success(movie: movie)
  end

  class Input < MovieValidation
  end
end

class Services::Movie::Edit < Servi
  attr_accessor :movie

  def build(input)
    # You would do
    # movie = movie.update(input)
    movie = self.movie

    success(movie: movie)
  end

  class Input < MovieValidation
  end
end

Cuba.plugin Cuba::Render
Cuba.settings[:render][:views] = "./examples/"

Cuba.define do
  on root do
    res.redirect "/new"
  end

  on get, "new" do
    form = Servi.empty_result
    res.write partial("form", form: form, action: "create")
  end

  on post, "create" do
    result = Services::Movie::Create.call(req.POST, {})

    if result.ok?
      movie = result[:movie]
      res.write("Movie created: #{movie.title}")
    else
      res.write partial("form", form: result, action: "create")
    end
  end

  on get, ":id/edit" do |id|
    # Fetch movie from DB
    movie = Movie.new(id, "The Hobbit", "Get that ring")

    form = Servi.empty_result
    form.input["title"] = movie.title
    form.input["body"] = movie.body

    res.write partial("form", form: form, action: "#{id}/edit")
  end

  on post, ":id/edit" do |id|
    # Fetch movie from DB
    movie = Movie.new(id, "The Hobbit", "Get that ring")

    result = Services::Movie::Edit.call(req.POST, { movie: movie })

    if result.ok?
      movie = result[:movie]
      res.write("Movie edited: #{movie.title}")
    else
      res.write partial("form", form: result, action: "#{id}/edit")
    end
  end
end

run Cuba
