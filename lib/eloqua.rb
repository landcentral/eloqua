require 'active_support/core_ext/class'
require 'active_support/core_ext/module'

module Eloqua
  
  autoload :Api, 'eloqua/api'
  autoload :Entity, 'eloqua/entity'
  autoload :Asset, 'eloqua/asset'
  autoload :RemoteObject, 'eloqua/remote_object'
	autoload :Query, 'eloqua/query'
  
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

  def self.delegate_with_args(from_klass, to_klass, methods, methods_to_argument)
    argument_string = methods_to_argument.join(', ')
    methods.each do |__method_name|
      from_klass.module_eval(<<-RUBY)
        def self.#{__method_name}(*args, &block)
          #{to_klass}.__send__(#{__method_name.inspect}, #{argument_string}, *args, &block)
        end
      RUBY
    end

  end

  
end
