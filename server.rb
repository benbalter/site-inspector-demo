require 'sinatra'
require 'rack/coffee'
require 'site-inspector'
require 'json'
require 'rack-cache'
require 'active_support/core_ext/string/inflections'
require 'tilt/erb'

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
        string.to_s.humanize.gsub(/\b(#{abbvs.join("|")})\b/i) { "#{$1}".upcase }
      end

      def format_key_value(key, value)

        if value.class == TrueClass
          c = "true"
        elsif value.class == FalseClass
          c = "false"
        else
          c = ""
        end

        if value =~ /^https?\:\//
          value = "<a href=\"#{value}\">#{value}</a>"
        end

        "<tr>
          <th>#{ format_key(key) }</th>
          <td class=\"#{c}\">#{ value }</td>
        </tr>"
      end
    end

    def render_template(template, locals={})
      halt erb template, :layout => :layout, :locals => locals
    end

    get "/" do
      render_template :index
    end

    get "/domains/:domain.json" do
      cache_control :public, max_age: GLOBAL_CACHE_TIMEOUT
      content_type :json
      domain = SiteInspector.new params[:domain]
      domain.to_h.to_json
    end

    get "/domains/:domain" do
      cache_control :public, max_age: GLOBAL_CACHE_TIMEOUT
      domain = SiteInspector.inspect params[:domain]
      render_template :domain, domain: domain, endpoint: domain.canonical_endpoint
    end
  end
end
