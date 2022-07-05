# frozen_string_literal: true

require 'sinatra'
require 'site-inspector'
require 'json'
require 'rack-cache'
require 'tilt/erb'
require 'cgi'
require 'urlscan'
require 'dotenv/load'
require 'rack/ecg'

GLOBAL_CACHE_TIMEOUT = 30

module SiteInspectorServer
  class App < Sinatra::Base
    configure :production do
      require 'rack-ssl-enforcer'
      use Rack::SslEnforcer
    end

    use Rack::ECG, checks: [
      [:static, { name: 'environment', value: Sinatra::Application.environment }],
    ]

    helpers SiteInspector::Formatter
    helpers do
      def slugify(word)
        word.to_s.downcase.tr(' ', '-')
      end
    end

    def render_template(template, locals = {})
      halt erb template, layout: :layout, locals: locals
    end

    def urlscan_client
      @urlscan_client ||= UrlScan::API.new
    end

    def urlscan(domain)
      urlscan_client.submit(domain.canonical_endpoint, visibility: 'private')
    rescue UrlScan::ProcessingError, UrlScan::RateLimited
      nil
    end

    get '/' do
      render_template :index
    end

    get '/domains/:domain.json' do
      cache_control :public, max_age: GLOBAL_CACHE_TIMEOUT
      content_type :json
      domain = SiteInspector.inspect params[:domain]
      domain.to_h.to_json
    end

    get '/domains/:domain' do
      cache_control :public, max_age: GLOBAL_CACHE_TIMEOUT
      domain = SiteInspector.inspect params[:domain]
      render_template :domain, domain: domain, endpoint: domain.canonical_endpoint, urlscan: urlscan(domain)
    end
  end
end
