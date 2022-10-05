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

end

# load the rake tasks
rf = File.join(File.dirname(__FILE__),"Rakefile")
load rf

