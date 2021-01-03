# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/clean"

require "rake/extensiontask"
Rake::ExtensionTask.new("libev_scheduler_ext") do |ext|
  ext.ext_dir = "ext/libev_scheduler"
end

task :recompile => [:clean, :compile]

task :default => [:compile, :test]
task :test do
  exec 'ruby test/run.rb'
end

task :stress_test do
  exec 'ruby test/stress.rb'
end

# task :docs do
#   exec 'RUBYOPT=-W0 jekyll serve -s docs -H ec2-18-156-117-172.eu-central-1.compute.amazonaws.com'
# end

CLEAN.include "**/*.o", "**/*.so", "**/*.so.*", "**/*.a", "**/*.bundle", "**/*.jar", "pkg", "tmp"
