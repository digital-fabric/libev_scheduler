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

CLEAN.include "**/*.o", "**/*.so", "**/*.so.*", "**/*.a", "**/*.bundle", "**/*.jar", "pkg", "tmp"
