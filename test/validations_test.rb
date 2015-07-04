require_relative "../lib/servi"
require "ostruct"

Post = OpenStruct

class Post::Create < Servi
  def build(attrs)
    post = Post.new(attrs)

    success(post: post)
  end

  def clean
    {
      title:    @params["title"],
      content:  @params["content"],
      category: @params["category"]
    }
  end

  def validate
    assert_present :title
    assert_present :content
    assert_present :category
  end
end

test "creates" do
  user_input = {
    "title"   => "How to paint with your hands",
    "content" => "Wash your hands in bucket of painting and place your hands in the canvas",
  }

  result = Post::Create.call(user_input, category: "arts")

  assert result.ok?
  post = result[:post]
  assert_equal "How to paint with your hands", post.title
  assert_equal "Wash your hands in bucket of painting and place your hands in the canvas", post.content
  assert_equal "arts", post.category

  assert_equal post, result.output[:post]
end

test "fails" do
  user_input = {
    "title"   => "How to paint with your hands",
  }

  result = Post::Create.call(user_input)

  assert !result.ok?
  assert_raise(KeyError) { result[:post] }
  assert result.errors[:content].include?(:not_present)
  assert result.errors[:category].include?(:not_present)
end


test "input is accessible" do
  user_input = {
    "title" => "How to paint with your hands",
    "content" => "Wash your hands in bucket of painting and place your hands in the canvas",
  }

  result = Post::Create.call(user_input, category: "arts")

  assert result.ok?
  assert_equal user_input.merge("category" => "arts"), result.params
end
