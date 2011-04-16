require 'eloqua/api'
require 'eloqua/entity'
require 'eloqua/asset'

module Eloqua
  
  autoload :Api, 'eloqua/api'
  autoload :Entity, 'eloqua/entity'
  
  mattr_accessor :user, :password
  
  def self.configure(&block)
    yield self
  end
  
  def self.authenticate(user, password)
    self.user = user
    self.password = password
  end

  def self.format_results_for_array(results, *keys)
    max_depth = keys.length
    depth = 0
    keys.each do |key|
      if(results.has_key?(key))
        depth += 1
        results = results[key]
      end
    end
    if(depth == max_depth && !results.is_a?(Array))
      results = [results]
    end
    results
  end

  
end
