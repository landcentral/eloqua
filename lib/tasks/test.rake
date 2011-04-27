require 'rspec/core/rake_task'
require 'ci/reporter/rake/rspec'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = './spec/**/*_spec.rb'
end

task :default => :spec
task :ci => ['hudson:spec']

namespace :hudson do
  task :spec => ["ci:setup:rspec",  'rake:spec']

  namespace :setup do

    task :pre_ci do
      require 'rubygems'
      gem 'ci_reporter'
      require 'ci/reporter/rake/rspec'
    end

    task :rspec => [:pre_ci, "ci:setup:rspec"]
  end
end
