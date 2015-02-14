require 'redis'
require 'redis/pool'
require 'redis/namespace'
require 'resque'
Resque.redis = Redis.new(url: ENV['REDISTOGO_URL'])
require 'resque/tasks'
require 'aws-sdk'
