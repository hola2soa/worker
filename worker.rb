require_relative 'bundle/bundler/setup'
require 'json'
require 'aws-sdk'
require 'httparty'

puts "Starting worker at #{Time.now}"

puts "Setting up AWS connection"
config = JSON.parse(File.read('config/config.json'))
ENV.update config
sqs = Aws::SQS::Client.new
q_url = sqs.get_queue_url({queue_name: 'RecentRequests'}).queue_url

puts "Polling SQS for messages"
poller = Aws::SQS::QueuePoller.new(q_url)
begin
  poller.poll(wait_time_seconds: nil, idle_timeout:5) do |msg|
    puts "MESSAGE #{JSON.parse(msg.body)}"
    req = JSON.parse msg.body
    results = HTTParty.get req['url']
    puts "RESULTS: #{results}\n"
  end
rescue Aws::SQS::Errors::ServiceError => e
  puts "ERROR FROM SQS #{e}"
end
