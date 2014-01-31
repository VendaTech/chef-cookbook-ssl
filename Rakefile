require 'rspec/core/rake_task'
require 'ci/reporter/rake/rspec'

task :default => [:spec]

desc "Run the specs."
RSpec::Core::RakeTask.new(:spec => ["ci:setup:rspec"]) do |t|
  t.pattern = "spec/**/*_spec.rb"
end
