# frozen_string_literal: true

class PostsController < ApplicationController
  before_action :authenticate_request!
  before_action :set_post, only: %i[show update destroy]

  def index
    @posts = current_user.posts.order(created_at: :desc)
    render 'posts/index'
  end

  def show
    render 'posts/show'
  end

  def create
    @post = current_user.posts.build(post_params)

    if @post.save
      render 'posts/show', status: :created
    else
      render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @post.update(post_params)
      render 'posts/show'
    else
      render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy!
    head :no_content
  end

  private

  def set_post
    @post = current_user.posts.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :body)
  end
end
