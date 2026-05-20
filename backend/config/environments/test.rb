# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

Rails.application.configure do
  config.secret_key_base = 'test_secret_key_base_minimum_length_32'
  config.enable_reloading = false
  config.eager_load = ENV['CI'].present?
  config.public_file_server.enabled = true
  config.public_file_server.headers = { 'Cache-Control' => "public, max-age=#{1.hour.to_i}" }
  config.consider_all_requests_local = true
  config.action_dispatch.show_exceptions = :rescuable
  config.cache_store = :null_store
  config.active_support.deprecation = :stderr
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []
  config.active_record.migration_error = :page_load
end
