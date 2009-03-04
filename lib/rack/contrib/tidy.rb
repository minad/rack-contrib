require 'open3'

module Rack
  class Tidy
    TIDY_CMD = 'tidy -i -xml -access 3 -quiet'
    XMLLINT_CMD = 'xmllint --format --valid --dtdvalid file:/tmp/xhtml11.dtd -'

    def initialize(app, options={})
      @app = app
      mode = options[:mode] || :tidy
      @cmd = mode == :tidy ? TIDY_CMD : XMLLINT_CMD
    end

    def call(env)
      status, header, body = response = @app.call(env)
      return response if !html?(header)
      Open3.popen3(@cmd) { |stdin, stdout, stderr|
        body.each {|x| stdin << x }
        stdin.close
        body = stdout.read
        errors = stderr.read.strip
        body +=  "<!--\n#{errors}\n-->\n" if !errors.blank?
      }
      header['Content-Length'] = body.length.to_s
      [status, header, body]
    end

    private

    def html?(header)
      %w(application/xhtml+xml text/html).any? do |type|
        header['Content-Type'].include?(type)
      end
    end
  end
end
