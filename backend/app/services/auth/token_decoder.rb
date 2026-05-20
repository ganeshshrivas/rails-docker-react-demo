# frozen_string_literal: true

module Auth
  class TokenDecoder
    def self.decode(token)
      body = JWT.decode(token, JwtConfig.secret!, true, algorithm: JwtConfig::ALGORITHM).first
      body.with_indifferent_access
    rescue JWT::DecodeError, JWT::ExpiredSignature
      nil
    end
  end
end
