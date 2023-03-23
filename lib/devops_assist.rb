# frozen_string_literal: true

require_relative "devops_assist/version"
require_relative 'devops_assist/release_log/release_log'

require_relative 'devops_assist/vcs/git/cli_prompt'

require_relative 'devops_assist/gem/gem'

require_relative 'devops_assist/version_manager'

require 'toolrack'
require 'teLogger'

module DevopsAssist
  class Error < StandardError; end
  # Your code goes here...

  EnvKey = "DEVOPS_ASSIST"
  EnvKeyGemReleasing = "#{EnvKey}_GEM_RELEASING"

  def self.is_debug_mode?
    val = ENV["DEVOPS_ASSIST_DEBUG"]
    (not val.nil? and val.downcase == "true")
  end

  def self.debug(msg)
    logger.tdebug(:devops_assist, msg) if is_debug_mode?
  end

  private
  def logger
    if @logger.nil?
      @logger = TeLogger::TLogger.new(STDOUT)
    end
    @logger
  end

end

# load the rake tasks
rf = File.join(File.dirname(__FILE__),"Rakefile")
load rf
