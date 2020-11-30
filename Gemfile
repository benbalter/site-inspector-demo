# frozen_string_literal: true

source 'https://rubygems.org'

ruby `cat .ruby-version`.strip

gem 'activerecord'
gem 'dotenv'
gem 'rack', '>= 1.5.2'
gem 'rack-cache'
gem 'rack-ssl-enforcer'
gem 'rubocop'
gem 'rubocop-performance'
gem 'sinatra'
if RUBY_PLATFORM.match?(/darwin/)
  gem 'site-inspector', path: '../site-inspector'
else
  gem 'site-inspector', github: 'benbalter/site-inspector'
end
gem 'sniffles', github: 'wa0x6e/sniffles'
gem 'urlscan'
