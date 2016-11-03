require "test_helper"
require "twiphy"

include Rack::Test::Methods

def app
  Sinatra::Application
end

describe "twiphy app" do

  after do
    WebMock.reset!
  end

  it "shows the form by default" do
    get "/"

    expect(last_response.ok?).must_equal true
    expect(last_response.body).must_include "GIF Search"
  end

  it "sends a GIF from giphy using the query provided" do
    stub_request(:get, "http://api.giphy.com/v1/gifs/translate?api_key=#{ENV["GIPHY_API_KEY"]}&s=meh").
        to_return(body: File.new('test/responses/giphy_translate_response.json'), status: 200)
    stub_request(:post, %r{https://api.twilio.com/.*}).
        to_return(body: File.new('test/responses/twilio_response.json'), status: 200)

    post "/message", query: "meh", phone: "617-555-4444"
    follow_redirect!

    expect(last_response.body).must_include "Your GIF should be arriving shortly"
  end

  it "sends a random GIF from giphy if no query is provided" do
    stub_request(:get, "http://api.giphy.com/v1/gifs/random?api_key=#{ENV["GIPHY_API_KEY"]}").
        to_return(body: File.new('test/responses/giphy_random_response.json'), status: 200)
    stub_request(:post, %r{https://api.twilio.com/.*}).
        to_return(body: File.new('test/responses/twilio_response.json'), status: 200)

    post "/message", phone: "617-555-4444"
    follow_redirect!

    expect(last_response.body).must_include "Your GIF should be arriving shortly"
  end

  it "displays an error if phone number is not provided" do
    post "/message", query: "meh"

    expect(last_response.body).must_include "Please enter a mobile number"
    expect(last_response.body).must_include "meh"
  end

end