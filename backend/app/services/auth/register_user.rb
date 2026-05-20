# frozen_string_literal: true

module Auth
  class RegisterUser
    def self.call(params)
      user = User.new(
        name: params[:name],
        email: params[:email],
        password: params[:password]
      )

      return Result.new(success: false, user: user, errors: user.errors.full_messages) unless user.save

      token = TokenEncoder.encode(user.id)
      Result.new(success: true, user: user, token: token)
    end

    Result = Struct.new(:success, :user, :token, :errors, keyword_init: true)
  end
end
