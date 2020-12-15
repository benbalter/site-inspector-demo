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
    ABBREVIATIONS = %w[
      acme cdn cms ui crm dns dnssec dnt hsts http https id ip ipv6 json paas pki sld ssl tld tls trd txt uri url whois www xml xss
    ].freeze

    configure :production do
      require 'rack-ssl-enforcer'
      use Rack::SslEnforcer
    end

    helpers do
      def format_key(string)
        string.to_s.gsub(/^x-/, '').tr('-', ' ').humanize.gsub(/\b(#{ABBREVIATIONS.join("|")})\b/i) do
          Regexp.last_match(1).to_s.upcase
        end
      end

      def format_value(value)
        value = if value.instance_of?(String)
                  CGI.escapeHTML(value.to_s)
                elsif value.instance_of?(Hash)
                  '<ul>' + value.map do |key, value|
                             "<li><span class='font-weight-bold'>#{key}</span>: #{format_value(value)}</li>"
                           end.join + '</ul>'
                elsif value.instance_of?(Array) && value.length == 1
                  format_value(value[0])
                elsif value.instance_of?(Array)
                  '<ol><li>' + value.map { |value| format_value(value) }.join('</li><li>') + '</li></ol>'
                else
                  value.to_s
                end

        value = "<a href=\"#{value}\">#{value}</a>" if %r{^https?:/}.match?(value.to_s)

        value
      end

      def format_key_value(key, value, check = nil)
        c = if value.instance_of?(TrueClass)
              'text-success'
            elsif value.instance_of?(FalseClass)
              'text-danger'
            else
              ''
            end

        output = '<tr>'.dup
        output << "<th>#{format_key(key)}</th>"
        output << "<td class=\"#{c}\">"

        uri = check&.uri_for(key)
        output << "<a href=\"#{uri}\" class=\"#{c}\">" if value == true && uri

        output << format_value(value)

        output << '</a>' if value == true && uri
        output << '</td>'
        output << '</tr>'
        output
      end

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
