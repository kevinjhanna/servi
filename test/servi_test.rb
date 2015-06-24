require File.expand_path("../lib/servi", File.dirname(__FILE__))

Post = Struct.new(:title, :content, :category)

class Post::Create < Servi
  attr_accessor :category

  class AdditionalValidation < ::Scrivener
    attr_accessor :category

    def validate
      assert_member  :category, %w(arts technology)
    end
  end

  def build(attrs)
    # Of course, this is silly since you would move this validation to
    # Input class. In this case, the validation is done in two steps.
    # Only after all variables in Input are valid, this additional validation would run.
    #
    # This error handling in the build phase might help when you can only validate
    # things after doing some processing.

    additional_validations = AdditionalValidation.new(category: category)

    if not additional_validations.valid?
      return error(additional_validations.errors)
    end

    attrs = attrs.merge(category: category)

    post = Post.new(
      attrs.fetch(:title),
      attrs.fetch(:content),
      attrs.fetch(:category),
    )

    success(post: post)
  end

  class Input < Servi::Input
    attr_accessor :title
    attr_accessor :content

    def validate
      assert_present :title
      assert_present :content
    end
  end
end

test "creates" do
  user_input = {
    "title" => "How to paint with your hands",
    "content" => "Wash your hands in bucket of painting and place your hands in the canvas",
  }

  service = Post::Create.new(user_input)
  service.category = "arts"
  result = service.commit

  assert result.ok?
  post = result[:post]
  assert_equal "How to paint with your hands", post.title
  assert_equal "Wash your hands in bucket of painting and place your hands in the canvas", post.content
  assert_equal "arts", post.category

  assert_equal post, result.output[:post]
end

test "input is accessible" do
  user_input = {
    "title" => "How to paint with your hands",
    "content" => "Wash your hands in bucket of painting and place your hands in the canvas",
  }

  result = Post::Create.(user_input, category: "arts")

  assert result.ok?
  assert_equal user_input, result.input
end

test "invalid options" do
  user_input = {
    "title" => "How to paint with your hands",
    "content" => "Wash your hands in bucket of painting and place your hands in the canvas",
  }

  service = Post::Create.new(user_input)
  service.category = "sports"
  result = service.commit

  assert !result.ok?
  assert_raise(KeyError) { result[:post] }
  assert result.errors[:category].include?(:not_valid)
end

test "does not fail with undeclared attribute" do
  user_input = { "user_id" => 1 }

  service = Post::Create.new(user_input)
  result = service.commit

  assert !result.ok?
end


# You can use validation_context when validating flows with external objects
# Usually those external objects are passed as trusted input.
#
# For example, you need to check if an instance belongs to it's user
# in order to delete it.

Comment = Struct.new(:content, :user_id)
RegisteredUser = Struct.new(:id)

class Comment::Delete < Servi
  attr_accessor :user

  def build(attrs)
    success(comment: nil)
  end

  def validation_context
    { user: user }
  end

  class Input < Servi::Input
    attr_accessor :comment

    def validate
      assert_present :comment
      assert(@context[:user].id == comment.user_id, [:user, :not_valid])
    end
  end
end

test "validation_context" do
  comment = Comment.new("It's great", 1)

  user = RegisteredUser.new(1)
  other_user = RegisteredUser.new(2)

  user_input = { comment: comment }

  service = Comment::Delete.new(user_input)
  service.user = other_user
  result = service.commit
  assert !result.ok?
  assert result.errors.on(:user, :not_valid)

  service.user = user
  result = service.commit
  assert result.ok?
  assert result[:comment].nil?
end

test "consistency of error methods" do
  # When it fails
  result = Post::Create.call({}, {})
  assert !result.ok?
  assert result.errors.on(:title, :not_present)

  # When it succeeds
  user_input = {
    "title" => "foo",
    "content" => "bar",
  }

  result = Post::Create.call(user_input, { category: "arts" })
  assert result.ok?
  assert !result.errors.on(:title, :not_present)
end
