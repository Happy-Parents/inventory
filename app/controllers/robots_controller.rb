class RobotsController < ActionController::Base
  def show
    render plain: Rails.env.production? ? DISALLOW_ALL : ALLOW_ALL,
           content_type: 'text/plain'
  end

  DISALLOW_ALL = <<~TXT
    # See https://www.robotstxt.org/robotstxt.html for documentation on how to use the robots.txt file
    User-agent: *
    Disallow: /
  TXT

  ALLOW_ALL = <<~TXT
    # See https://www.robotstxt.org/robotstxt.html for documentation on how to use the robots.txt file
    User-agent: *
    Allow: /
  TXT
end
