#!/bin/ruby
require 'sinatra'
require 'json'
require 'rest-client'

set :bind, '0.0.0.0'

post '/github/push-event' do
  request.body.rewind
  payload_body = request.body.read
  verify_signature(payload_body)
  push = JSON.parse(params[:payload])
  puts "I got some JSON: #{push.inspect}"
end

post '/docker-hub/build-complete' do
  request.body.rewind  # in case someone already read it
  data = JSON.parse request.body.read

  uri = URI(data['callback_url'])
  http = Net::HTTP.new(uri.host)
  req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
  req.body = {"state": "success"}.to_json
  res = http.request(req)

  puts "response #{res.body}"
end

def verify_signature(payload_body)
  signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), 
						ENV['SECRET_TOKEN'], 
						payload_body)

  return halt 500, "Signatures didn't match!" unless 
	Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
end