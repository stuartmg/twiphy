ENV['RACK_ENV'] = 'test'

require "minitest/autorun"
require "rack/test"
require "webmock/minitest"

require File.expand_path '../../twiphy.rb', __FILE__

WebMock.disable_net_connect!
