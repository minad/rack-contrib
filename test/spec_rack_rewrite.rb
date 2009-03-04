require 'test/spec'
require 'rack/mock'
require 'rack/contrib/rewrite'

context "Rack::Rewrite" do

  def action(id, expect)
    response = Rack::MockRequest.new(@app).get("/~user/app/action#{id}")
    response.body.should.equal(expect)
    response.status.should.equal(200)
  end

  specify "should rewrite absolute paths" do
    @app = Rack::Builder.new do
      use Rack::Lint
      use Rack::Rewrite, :base => '/~user/app'
      run Rack::URLMap.new({
                             '/action1' => lambda { [200, {"Content-Type" => "text/html"}, ['<a href="/action">']] },
                             '/action2' => lambda { [200, {"Content-Type" => "text/html"}, ['<a href=\'/action\'>']] },
                             '/action3' => lambda { [200, {"Content-Type" => "text/html"}, ['<a href="http://xy">']] },
                             '/action4' => lambda { [200, {"Content-Type" => "text/html"}, ['<a href="relative">']] },
                             '/action5' => lambda { [200, {"Content-Type" => "text/html"}, ['<img title="image" src="/img"/>']] },
                             '/action6' => lambda { [200, {"Content-Type" => "text/html"}, ['<link rel="stylesheet" href="/style.css" type="text/css">']] },
                           })
    end

    action(1, '<a href="/~user/app/action">')
    action(2, '<a href=\'/~user/app/action\'>')
    action(3, '<a href="http://xy">')
    action(4, '<a href="relative">')
    action(5, '<img title="image" src="/~user/app/img"/>')
    action(6, '<link rel="stylesheet" href="/~user/app/style.css" type="text/css">')
  end

end
