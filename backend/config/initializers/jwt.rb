# frozen_string_literal: true

module JwtConfig
  SECRET = ENV.fetch('JWT_SECRET') do
    if Rails.env.development? || Rails.env.test?
      'development_jwt_secret_change_in_production'
    end
  end
  ALGORITHM = 'HS256'
  EXPIRATION = 24.hours

  def self.secret!
    SECRET || raise('JWT_SECRET environment variable is required')
  end
end
