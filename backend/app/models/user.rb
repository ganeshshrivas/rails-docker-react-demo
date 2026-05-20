# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  has_many :posts, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: 6 }, on: :create

  normalizes :email, with: ->(email) { email.strip.downcase }
end
