# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    fixtures :all
  end
end

class ActionDispatch::IntegrationTest
  def auth_headers(user)
    token = Auth::TokenEncoder.encode(user.id)
    { 'Authorization' => "Bearer #{token}" }
  end
end
