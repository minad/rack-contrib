require 'open3'

module Rack
  # Rack::Tidy cleans markup and validates it.
  # It adds a comment with the errors at the end.
  #
  # You can specify tidy/xmllint via the mode options.

  class Tidy
    TIDY_CMD = 'tidy -i -xml -access 3 -quiet'
    XMLLINT_CMD = 'xmllint --format --valid -'

    def initialize(app, options={})
      @app = app
      mode = options[:mode] || 'tidy'
      @cmd = mode.to_s == 'tidy' ? TIDY_CMD : XMLLINT_CMD
    end

    def call(env)
      status, header, body = response = @app.call(env)
      return response if !html?(header)
      Open3.popen3(@cmd) { |stdin, stdout, stderr|
        body.each {|x| stdin << x }
        stdin.close
        body = stdout.read
        errors = stderr.read.strip
        body +=  "<!--\n#{errors}\n-->\n" if !errors.empty?
      }
      header['Content-Length'] = body.length.to_s
      [status, header, body]
    end

    private

    def html?(header)
      %w(application/xhtml+xml text/html text/xml).any? do |type|
        header['Content-Type'].to_s.include?(type)
      end
    end
  end
end
