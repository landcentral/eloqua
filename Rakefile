require 'rake'
require 'rake/tasklib'
require 'rubygems'
require 'bundler'

Bundler.setup(:default, :test)


Dir["lib/tasks**/*.rake"].each do |file| 
  puts file
  load(file)
end
