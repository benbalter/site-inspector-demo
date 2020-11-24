# frozen_string_literal: true

require 'sinatra'
require 'site-inspector'
require 'json'
require 'rack-cache'
require 'active_support/core_ext/string/inflections'
require 'tilt/erb'
require 'cgi'
require 'urlscan'
require 'dotenv/load'

GLOBAL_CACHE_TIMEOUT = 30

module SiteInspectorServer
  class App < Sinatra::Base
    configure :production do
      require 'rack-ssl-enforcer'
      use Rack::SslEnforcer
    end

    helpers do
      def format_key(string)
        abbvs = %w[www https hsts url dnssec ipv6 cdn xml txt ip xss dns uri]
        string.to_s.gsub(/^x-/, '').tr('-', ' ').humanize.gsub(/\b(#{abbvs.join("|")})\b/i) { Regexp.last_match(1).to_s.upcase }
      end

      def format_value(value)
        if value.instance_of?(String)
          value = CGI.escapeHTML(value)
        elsif value.instance_of?(Hash)
          value = '<ul>' + value.map { |key, value| "<li><strong>#{key}</strong>: #{format_value(value)}</li>" }.join + '</ul>'
        elsif value.instance_of?(Array)
          value = '<ol><li>' + value.map { |value| format_value(value) }.join('</li><li>') + '</li></ul>'
        elsif value.instance_of?(Whois::Record)
          value = "<pre>#{CGI.escapeHTML(value.to_s)}</pre>"
        end

        value = "<a href=\"#{value}\">#{value}</a>" if %r{^https?:/}.match?(value.to_s)

        value
      end

      def format_key_value(key, value)
        c = if value.instance_of?(TrueClass)
              'true'
            elsif value.instance_of?(FalseClass)
              'false'
            else
              ''
            end

        "<tr>
          <th>#{format_key(key)}</th>
          <td class=\"#{c}\">#{format_value(value)}</td>
        </tr>"
      end
    end

    def render_template(template, locals = {})
      halt erb template, layout: :layout, locals: locals
    end

    def urlscan_client
      @urlscan_client ||= UrlScan::API.new
    end

    def urlscan(domain)
      urlscan_client.submit(domain.canonical_endpoint, false)
    rescue UrlScan::ProcessingError
      nil
    end

    get '/' do
      render_template :index
    end

    get '/domains/:domain.json' do
      cache_control :public, max_age: GLOBAL_CACHE_TIMEOUT
      content_type :json
      domain = SiteInspector.new Addressable::URI.parse(params[:domain]).host
      domain.to_h.to_json
    end

    get '/domains/:domain' do
      cache_control :public, max_age: GLOBAL_CACHE_TIMEOUT
      domain = SiteInspector.inspect params[:domain]
      render_template :domain, domain: domain, endpoint: domain.canonical_endpoint, urlscan: urlscan(domain)
    end
  end
end
