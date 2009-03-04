require 'cgi'

module Rack
  # Rack::Rewrite rewrites absolute paths to another base.
  # If you have an application for / which you want to install under /~user/app
  # then you can use this middleware.
  # You have to specify the base as option.

  class Rewrite

    def initialize(app, options={})
      raise ArgumentError, 'Base option is missing' if !options[:base]
      @app = app
      @base = options[:base]
      @base.gsub!(%r{^/+|/+$}, '')
    end

    def call(env)
      if env['PATH_INFO'] =~ %r{^/#{@base}$|^/#{@base}/}
        env['PATH_INFO'] = env['PATH_INFO'].to_s.sub(%r{^/#{@base}/?}, '/')
        env['REQUEST_URI'] = env['REQUEST_URI'].to_s.sub(%r{^/#{@base}/?}, '/')

        status, header, body = @app.call(env)

        if [301, 302, 303, 307].include?(status)
          header['Location'] = '/' + @base + header['Location'] if header['Location'][0..0] == '/'
        elsif ![204, 304].include?(status) && html?(header)
          tmp = ''
          body.each {|data| tmp << data}
          body = tmp
          body.gsub!(/(<(a|img|link|script|input|area|form)\s[^>]*(src|href|action)=["'])\/([^"']*["'])/m, "\\1/#{@base}/\\4")
          header['Content-Length'] = body.length.to_s
        end
        [status, header, body]
      else
        response = Response.new
        response.write "Webserver is not configured correctly. <a href=\"/#{@base}\">Application is available under /#{@base}</a><p>#{CGI::escapeHTML env.inspect}</p>"
        response.finish
      end
    end

    private

    def html?(header)
      %w(application/xhtml+xml text/html).any? do |type|
        header['Content-Type'].to_s.include?(type)
      end
    end
  end
end
