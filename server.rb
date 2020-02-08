# frozen_string_literal: true

require 'sinatra'
require 'rack/coffee'
require 'site-inspector'
require 'json'
require 'rack-cache'
require 'active_support/core_ext/string/inflections'
require 'tilt/erb'
require 'cgi'

GLOBAL_CACHE_TIMEOUT = 30

module SiteInspectorServer
  class App < Sinatra::Base
    use Rack::Coffee, root: 'public', urls: '/assets/javascripts'

    configure :production do
      require 'rack-ssl-enforcer'
      use Rack::SslEnforcer
    end

    helpers do
      def format_key(string)
        abbvs = %w[www https hsts url dnssec ipv6 cdn xml txt ip xss dns uri]
        string.to_s.humanize.gsub(/\b(#{abbvs.join("|")})\b/i) { Regexp.last_match(1).to_s.upcase }
      end

      def format_value(value)
        if value.class == String
          value = CGI.escapeHTML(value)
        elsif value.class == Hash
          value = '<ul>' + value.map { |key, value| "<li><strong>#{key}</strong>: #{format_value(value)}</li>" }.join + '</ul>'
        elsif value.class == Array
          value = '<ol><li>' + value.map { |value| format_value(value) }.join('</li><li>') + '</li></ul>'
        elsif value.class == Whois::Record
          value = "<pre>#{CGI.escapeHTML(value.to_s)}</pre>"
        end

        value = "<a href=\"#{value}\">#{value}</a>" if value =~ %r{^https?\:/}

        value
      end

      def format_key_value(key, value)
        c = if value.class == TrueClass
              'true'
            elsif value.class == FalseClass
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

    get '/' do
      render_template :index
    end

    get '/domains/:domain.json' do
      cache_control :public, max_age: GLOBAL_CACHE_TIMEOUT
      content_type :json
      domain = SiteInspector.new params[:domain]
      domain.to_h.to_json
    end

    get '/domains/:domain' do
      cache_control :public, max_age: GLOBAL_CACHE_TIMEOUT
      domain = SiteInspector.inspect params[:domain]
      render_template :domain, domain: domain, endpoint: domain.canonical_endpoint
    end
  end
end
