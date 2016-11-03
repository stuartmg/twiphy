require 'sinatra'
require 'sinatra/flash'
require 'securerandom'

require 'twilio-ruby'
require 'e164'

require 'json'
require 'rest-client'

STDOUT.sync = true

configure do
  enable :sessions

  set :session_secret, SecureRandom.hex
  set :giphy_api_key, ENV["GIPHY_API_KEY"]
end

get "/" do
  erb :index
end

post "/message" do
  if normalized_phone
    begin
      phone = normalized_phone
      image = image_to_send

      puts "Sending image to #{phone}: #{image}"

      twilio_client.account.messages.create({
        from: from_number,
        to: phone,
        body: "Powered By Giphy and Twilio", # make sure to comply with Giphy API terms of service
        media_url: image
      })

      flash[:notice] = "Your GIF should be arriving shortly"
    rescue Exception => e
      flash[:alert] = "There was a problem sending you a GIF: #{e.message}"
    end

    redirect "/"
  else
    flash.now[:alert] = "Please enter a mobile number"
    erb :index
  end
end

private

def from_number
  ENV["TWILIO_FROM_NUMBER"]
end

def normalized_phone
  phone_number = params[:phone] || ""

  if phone_number.strip.empty?
    nil
  else
    E164.normalize phone_number
  end
end

def twilio_client
  Twilio::REST::Client.new ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"]
end

def image_to_send
  query = params[:query] || ""

  if query.strip.empty?
    fetch_random
  else
    fetch_image query
  end
end

def fetch_image(query)
  res = RestClient.get "http://api.giphy.com/v1/gifs/translate?api_key=#{settings.giphy_api_key}&s=#{URI.encode(query)}"

  JSON.parse(res)["data"]["images"]["original"]["url"]
end

def fetch_random
  res = RestClient.get "http://api.giphy.com/v1/gifs/random?api_key=#{settings.giphy_api_key}"

  JSON.parse(res)["data"]["image_url"]
end

