require 'rubygems'
require "bundler/setup"
require 'flexmock'

require 'net/http'
require 'net/https'

Bundler.require :default, :test

require 'rspec'
require 'timecop'
require 'eloqua'

unless defined?(ELOQUA_LIB)
  ELOQUA_LIB = File.dirname(__FILE__) + '/../lib'
  $: << ELOQUA_LIB
end

Dir[File.dirname(__FILE__) + '/support/**/*.rb'].each {|support| require support}
Dir[File.dirname(__FILE__) + '/shared/**/*.rb'].each {|support| require support}

RSpec.configure do |config|
  
  include Eloqua::RSpec::Helper
  Savon::Spec::Fixture.path = File.dirname(__FILE__) + '/fixtures/'
  
  config.mock_with :flexmock
  
  config.before do
    # This is for adding actual authentication details.
    # The core tests do not actually need to login as they 
    # operate on fixtures but we need to get the fixture data
    # in the first place and for that valid authenticate is needed
    initializer = File.dirname(__FILE__) + '/../eloqua_initializer.rb'
    if(File.exist?(initializer))
      load initializer
    else
      Eloqua.authenticate('company\\user', 'pass')
    end
  end
  
end
