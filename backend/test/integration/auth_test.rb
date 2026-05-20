# frozen_string_literal: true

require 'test_helper'

class AuthTest < ActionDispatch::IntegrationTest
  test 'signup creates user and returns token' do
    assert_difference 'User.count', 1 do
      post '/signup', params: {
        user: { name: 'New User', email: 'new@example.com', password: 'password123' }
      }, as: :json
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert body['token'].present?
    assert_equal 'new@example.com', body['user']['email']
  end

  test 'login returns token for valid credentials' do
    post '/login', params: {
      user: { email: users(:one).email, password: 'password123' }
    }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert body['token'].present?
  end

  test 'login rejects invalid credentials' do
    post '/login', params: {
      user: { email: users(:one).email, password: 'wrong' }
    }, as: :json

    assert_response :unauthorized
  end
end
