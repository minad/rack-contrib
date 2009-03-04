module Rack
  class Rewrite

    def initialize(app, options={})
      @app = app
      @base = options[:base]
      @base.gsub!(%r{^/+|/+$}, '')
    end

    def call(env)
      if env['PATH_INFO'] =~ %r{^/#{@base}$|^/#{@base}/}
        env['PATH_INFO'] = env['PATH_INFO'].sub(%r{^/#{@base}/?}, '/')
        env['REQUEST_URI'] = env['REQUEST_URI'].sub(%r{^/#{@base}/?}, '/')

        status, header, body = @app.call(env)

        if [301, 302, 303, 307].include?(status)
          header['Location'] = '/' + @base + header['Location']
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
        header['Content-Type'].include?(type)
      end
    end
  end
end
