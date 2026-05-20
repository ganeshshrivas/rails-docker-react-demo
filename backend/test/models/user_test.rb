# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'requires email and password on create' do
    user = User.new(name: 'Name')
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
    assert_includes user.errors[:password], "can't be blank"
  end

  test 'email must be unique' do
    users(:one).dup.tap { |u| u.email = users(:one).email }.valid?
    duplicate = User.new(name: 'Other', email: users(:one).email, password: 'password123')
    assert_not duplicate.valid?
  end
end
