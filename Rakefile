require 'redis'
require 'redis/pool'
require 'redis/namespace'
require 'resque'
require './jobs/capture'
Resque.redis = Redis.new(url: ENV['REDISTOGO_URL'])
require 'resque/tasks'
require 'aws-sdk'
