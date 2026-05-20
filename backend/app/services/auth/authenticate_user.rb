# frozen_string_literal: true

module Auth
  class AuthenticateUser
    def self.call(email:, password:)
      user = User.find_by(email: email.to_s.strip.downcase)

      unless user&.authenticate(password)
        return Result.new(success: false, error: 'Invalid email or password')
      end

      token = TokenEncoder.encode(user.id)
      Result.new(success: true, user: user, token: token)
    end

    Result = Struct.new(:success, :user, :token, :error, keyword_init: true)
  end
end
