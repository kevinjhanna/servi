require "cuba"
require "cuba/render"
require "erb"
require "ostruct"

require_relative "../lib/servi"

module Services
  class Movie
  end
end

Movie = OpenStruct

class Services::Movie::Create < Servi
  def build(attrs)
    # You would do
    # movie = Movie.create(attrs)

    movie = Movie.new(attrs.merge(id: 1))
    success(movie: movie)
  end

  def validate
    assert_present :title
    assert_present :body
  end

  def clean
    {
      title: @params["title"],
      body: @params["title"]
    }
  end
end

class Services::Movie::Edit < Servi
  def build(attrs)
    # You would do
    # movie = movie.update(attrs)
    movie = attrs[:movie]

    success(movie: movie)
  end

  def validate
    assert_present :movie
    assert_present :title
    assert_present :body
  end

  def clean
    {
      movie: @params["movie"],
      title: @params["title"],
      body: @params["title"]
    }
  end
end

Cuba.plugin Cuba::Render
Cuba.settings[:render][:views] = "./examples/"

Cuba.define do
  on root do
    res.redirect "/new"
  end

  on get, "new" do
    result = Servi::Result.unbounded
    res.write partial("form", form: result, action: "create")
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
    movie = Movie.new(id: id, title: "The Hobbit", body: "Get that ring")

    result = Servi::Result.unbounded
    result.params["title"] = movie.title
    result.params["body"] = movie.body

    res.write partial("form", form: result, action: "#{id}/edit")
  end

  on post, ":id/edit" do |id|
    # Fetch movie from DB
    movie = Movie.new(id: id, title: "The Hobbit", body: "Get that ring")

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
