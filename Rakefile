# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

#require_relative './lib/devops_assist'
require File.join(File.dirname(__FILE__),"lib","devops_assist") #'./lib/devops_assist'

task default: :spec
