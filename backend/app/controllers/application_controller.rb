# frozen_string_literal: true

class ApplicationController < ActionController::API
  include Authenticable

  before_action :set_default_format

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request

  private

  def set_default_format
    request.format = :json if request.format.html?
  end

  def not_found
    render json: { error: 'Record not found' }, status: :not_found
  end

  def bad_request(exception)
    render json: { error: exception.message }, status: :bad_request
  end
end
