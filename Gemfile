# frozen_string_literal: true

source 'https://rubygems.org'

gem 'activerecord'
gem 'dotenv'
gem 'rack'
gem 'rack-cache'
gem 'rack-ssl-enforcer'

gem 'sinatra', ">= 2.0.0"
gem 'rack-ecg'
gem 'puma'


if ENV['LOCAL']
  gem 'site-inspector', path: '../site-inspector'
else
  gem 'site-inspector', github: 'benbalter/site-inspector'
end
gem 'sniffles', github: 'wa0x6e/sniffles'
gem 'gman', github: 'benbalter/gman'
gem 'urlscan'

group :development do
  gem 'rubocop'
  gem 'rubocop-performance'
end