# frozen_string_literal: true

module Auth
  class TokenEncoder
    def self.encode(user_id)
      payload = {
        user_id: user_id,
        exp: JwtConfig::EXPIRATION.from_now.to_i
      }
      JWT.encode(payload, JwtConfig.secret!, JwtConfig::ALGORITHM)
    end
  end
end
