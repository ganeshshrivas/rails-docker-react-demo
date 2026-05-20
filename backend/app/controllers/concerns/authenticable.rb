# frozen_string_literal: true

module Authenticable
  extend ActiveSupport::Concern

  included do
    attr_reader :current_user
  end

  private

  def authenticate_request!
    token = bearer_token
    return render_unauthorized('Missing token') if token.blank?

    payload = Auth::TokenDecoder.decode(token)
    return render_unauthorized('Invalid or expired token') if payload.blank?

    @current_user = User.find_by(id: payload[:user_id])
    return render_unauthorized('User not found') unless @current_user
  end

  def bearer_token
    header = request.headers['Authorization']
    return if header.blank?

    header.split.last
  end

  def render_unauthorized(message)
    render json: { error: message }, status: :unauthorized
  end
end
