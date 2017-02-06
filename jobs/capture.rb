require 'aws-sdk'
Resque.redis = Redis.new(url: ENV['REDISTOGO_URL'] || 'redis://redis:6379')
module Capture
	@queue = :default

	def self.perform(user, id)
		file = "#{user}_#{id}.png"
		require 'capybara-webkit'
		driver = Capybara::Webkit::Driver.new('web_capture')
		browser = driver.browser
		browser.visit "http://prgrphs.tokyo/#{user}/#{id}"
		browser.window_resize(browser.get_window_handle, 500, 500)
		browser.render(file, 500, 500)
		system "convert -crop 10000x10000+25+25 -trim -border 10x10 -bordercolor white #{file} #{file}"
		bucket = ::AWS::S3.new.buckets['prgrphs-images']
		object = bucket.objects["#{user}/#{id}.png"]
		object.write File.read(file)
		object.acl = :public_read
		File.unlink(file)
	end
end
