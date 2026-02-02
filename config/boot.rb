ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "logger" # Required for Ruby 3.1+ compatibility with Rails 6.1
require "bootsnap/setup" # Speed up boot time by caching expensive operations.
