require "cuba"
require "cuba/render"
require "erb"
require "ostruct"

require_relative "../lib/servi"
require_relative "../lib/servi/form"

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

module Forms
  module Movie
    class Edit < Servi::Form
      def fill(movie:)
        params["title"] = movie.title
        params["body"] = movie.body
      end
    end
  end
end

Cuba.plugin Cuba::Render
Cuba.settings[:render][:views] = "./examples/"

Cuba.define do
  on root do
    res.redirect "/new"
  end

  on get, "new" do
    form = Servi::Form.empty
    res.write partial("form", form: form, action: "create")
  end

  on post, "create" do
    result = Services::Movie::Create.call(req.POST, {})

    if result.ok?
      movie = result[:movie]
      res.write("Movie created: #{movie.title}")
    else
      form = Servi::Form.new(result)
      res.write partial("form", form: form, action: "create")
    end
  end

  on get, ":id/edit" do |id|
    # Fetch movie from DB
    movie = Movie.new(id: id, title: "The Hobbit", body: "Get that ring")

    form = Forms::Movie::Edit.from(movie: movie)

    res.write partial("form", form: form, action: "#{id}/edit")
  end

  on post, ":id/edit" do |id|
    # Fetch movie from DB
    movie = Movie.new(id: id, title: "The Hobbit", body: "Get that ring")

    result = Services::Movie::Edit.call(req.POST, { movie: movie })

    if result.ok?
      movie = result[:movie]
      res.write("Movie edited: #{movie.title}")
    else
      form = Servi::Form.new(result)
      res.write partial("form", form: form, action: "#{id}/edit")
    end
  end
end

run Cuba
