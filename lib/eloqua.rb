require 'eloqua/api'
require 'eloqua/entity'
require 'eloqua/asset'

module Eloqua
  
  autoload :API, 'eloqua/api'
  autoload :Entity, 'eloqua/entity'
  
  mattr_accessor :user, :password
  
  def self.configure(&block)
    yield self
  end
  
  def self.authenticate(user, password)
    self.user = user
    self.password = password
  end
  
end