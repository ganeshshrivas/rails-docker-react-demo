# frozen_string_literal: true

require 'test_helper'

class PostsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @headers = auth_headers(@user)
    @post = posts(:one)
  end

  test 'index returns only current user posts' do
    get '/posts', headers: @headers, as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert body.all? { |p| p['user_id'] == @user.id }
  end

  test 'cannot access another users post' do
    other = User.create!(name: 'Other', email: 'other@example.com', password: 'password123')
    other_post = other.posts.create!(title: 'Secret', body: 'Hidden')

    get "/posts/#{other_post.id}", headers: @headers, as: :json
    assert_response :not_found
  end

  test 'create update destroy post' do
    post '/posts', params: { post: { title: 'New', body: 'Body' } }, headers: @headers, as: :json
    assert_response :created
    created = JSON.parse(response.body)

    put "/posts/#{created['id']}", params: { post: { title: 'Updated' } }, headers: @headers, as: :json
    assert_response :success
    assert_equal 'Updated', JSON.parse(response.body)['title']

    delete "/posts/#{created['id']}", headers: @headers, as: :json
    assert_response :no_content
  end
end
