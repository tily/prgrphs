Bundler.require
require_relative "../models/user.rb"
Mongoid.load!("mongoid.yml")
Resque.redis = Redis.new(url: ENV['REDISTOGO_URL'] || 'redis://redis:6379')
module Capture
  @queue = :default

  def self.perform(user, id, share_on_twitter)
    url = "https://#{ENV['VIRTUAL_HOST']}/#{user}/#{id}"
    file = "#{user}_#{id}.png"
    require 'capybara-webkit'
    driver = Capybara::Webkit::Driver.new('web_capture')
    browser = driver.browser
    browser.visit(url + '?simple=true')
    browser.window_resize(browser.get_window_handle, 500, 500)
    browser.render(file, 500, 500)
    system "convert -crop 10000x10000+25+25 -trim -border 10x10 -bordercolor white #{file} #{file}"
    bucket = ::AWS::S3.new.buckets['prgrphs-images']
    object = bucket.objects["#{user}/#{id}.png"]
    object.write File.read(file)
    object.acl = :public_read
    twitter(user).update_with_media(url, File.new(file)) if share_on_twitter
    File.unlink(file)
  end


  def self.twitter(user)
    user = User.where(screen_name: user).first
    Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV["CONSUMER_KEY"]
      config.consumer_secret     = ENV["CONSUMER_SECRET"]
      config.access_token        = user.twitter_token
      config.access_token_secret = user.twitter_secret
    end
  end
end
