# frozen_string_literal: true

class AuthController < ApplicationController
  def signup
    result = Auth::RegisterUser.call(signup_params)

    if result.success
      @user = result.user
      @token = result.token
      render 'auth/session', status: :created
    else
      render json: { errors: result.errors }, status: :unprocessable_entity
    end
  end

  def login
    result = Auth::AuthenticateUser.call(
      email: login_params[:email],
      password: login_params[:password]
    )

    if result.success
      @user = result.user
      @token = result.token
      render 'auth/session'
    else
      render json: { error: result.error }, status: :unauthorized
    end
  end

  private

  def signup_params
    params.require(:user).permit(:name, :email, :password)
  end

  def login_params
    params.require(:user).permit(:email, :password)
  end
end
