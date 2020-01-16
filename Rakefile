begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'rdoc/task'
require 'rubocop/rake_task'

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Zaikio::JWTAuth'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.md')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

require 'bundler/gem_tasks'

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end

task default: :test

namespace :test do
  desc 'Runs RuboCop on specified directories'
  RuboCop::RakeTask.new(:rubocop) do |task|
    task.fail_on_error = false
  end
end

Rake::Task[:test].enhance ['test:rubocop']
