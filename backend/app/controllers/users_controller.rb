# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authenticate_request!

  def me
    @user = current_user
    render 'users/show'
  end
end
