# frozen_string_literal: true
# Require this file at the top of each feature spec.
require 'support/rails'
require 'support/capybara'
require 'support/poltergeist'
require 'support/authentication'
require 'support/factories'
require 'support/cleanup'
require 'support/helpers/fixtures'
require 'support/mail'
require 'support/helpers/generic_files'
require 'support/selectors'
require 'support/helpers/collections'
require 'support/helpers/ajax'
require 'support/helpers/locations'
require 'support/helpers/proxies'
require 'support/vcr'
require 'support/clamav'
require 'byebug' unless ENV['TRAVIS']
