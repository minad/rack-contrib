require 'test/spec'
require 'rack/mock'
require 'rack/contrib/tidy'

context "Rack::Tidy" do

  specify "should run tidy on xml" do
    app = Rack::Builder.new do
      use Rack::Lint
      use Rack::Tidy
      run Rack::URLMap.new({
                             "/valid" => lambda { [200, {"Content-Type" => "text/html"}, File.open('test/valid.html')] },
                             "/invalid" => lambda { [200, {"Content-Type" => "text/html"}, File.open('test/invalid.html')] },
                           })
    end
    response = Rack::MockRequest.new(app).get('/valid')
    response.status.should.equal(200)
    response.body.should.equal(File.read('test/valid.html'))

    response = Rack::MockRequest.new(app).get('/invalid')
    response.status.should.equal(200)
    response.body.should.equal(File.read('test/invalid-output.html'))
  end

  specify "should not run tidy on non-xml" do
    app = Rack::Builder.new do
      use Rack::Lint
      use Rack::Tidy
      run Rack::URLMap.new({
                             "/image" => lambda { [200, {"Content-Type" => "image/png", "Content-Length" => "9"}, ['>no html<']] },
                           })
    end
    response = Rack::MockRequest.new(app).get('/image')
    response.status.should.equal(200)
    response.body.should.equal('>no html<')
  end

end
