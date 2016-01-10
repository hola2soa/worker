require_relative 'bundle/bundler/setup'
require 'json'
require 'aws-sdk'
require 'httparty'
require 'dynamoid'
require 'net/smtp'
require 'mandrill'
require 'net/http'
require 'JSON'

require_relative './models/User'

puts "Starting worker at #{Time.now}"
puts "Setting up AWS connection"
config = JSON.parse(File.read('config/config.json'))
ENV.update config

Aws.config.update({
  region: ENV['AWS_REGION'],
  credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
})

Dynamoid.configure do |config|
  config.adapter = 'aws_sdk_v2'
  config.namespace = 'wss'
  config.warn_on_scan = false
  config.read_capacity = 1
  config.write_capacity = 1
end

mandrill = Mandrill::API.new ENV['MANDRILL_KEY']

def content email, inner_content
  {
    "to"=> [
      {
        "name" =>"Hola User",
        "type" =>"to",
        "email"=> email
      }
    ],
    "from_name"=>"Hola Worla",
    "subject"=>"推薦你最新的服飾！",
    "html"=> inner_content,
    "from_email"=>"holaworld@holaworld.com",
  }
end

def html_content(items)
  "
    <div>
      嗨！這些是今天要推薦你的本日新貨！
      <ul>
        <li style='list-style:none; display: inline-block'>
          <a href='#{items[0]["link"]}'>
            <img style='max-width: 250px' src='#{items[0]["images"][0]}' alt=''>
          </a>
          <p>#{items[0]["title"]}</p>
          <p>$#{items[0]["price"]}</p>
        </li>
        <li style='list-style:none; display: inline-block'>
          <a href='#{items[1]["link"]}'>
            <img style='max-width: 250px' src='#{items[1]["images"][0]}' alt=''>
          </a>
          <p>#{items[1]["title"]}</p>
          <p>$#{items[1]["price"]}</p>
        </li>
        <li style='list-style:none; display: inline-block'>
          <a href='#{items[2]["link"]}'>
            <img style='max-width: 250px' src='#{items[2]["images"][0]}' alt=''>
          </a>
          <p>#{items[2]["title"]}</p>
          <p>$#{items[2]["price"]}</p>
        </li>
        <li style='list-style:none; display: inline-block'>
          <a href='#{items[3]["link"]}'>
            <img style='max-width: 250px' src='#{items[3]["images"][0]}' alt=''>
          </a>
          <p>#{items[3]["title"]}</p>
          <p>$#{items[3]["price"]}</p>
        </li>
        <li style='list-style:none; display: inline-block'>
          <a href='#{items[4]["link"]}'>
            <img style='max-width: 250px' src='#{items[4]["images"][0]}' alt=''>
          </a>
          <p>#{items[4]["title"]}</p>
          <p>$#{items[4]["price"]}</p>
        </li>
      </ul>
    </div>
  "
end

res   = Net::HTTP.get_response(URI('https://wss-dynamo.herokuapp.com/api/v1/random_items?random=5'))
items = JSON.parse(res.body)
inner_content = html_content(items)

User.all.map do |user|
  puts "prepare to send to #{user.email_address}"
  message = content(user.email_address, inner_content)
  mandrill.messages.send message
  puts "sent!"
end
