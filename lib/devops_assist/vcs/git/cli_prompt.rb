
require 'git_cli_prompt'

module DevopsAssist
  module Vcs
    module Git
      class CliPrompt
        include GitCliPrompt::Commit
        include GitCliPrompt::Tag
        include GitCliPrompt::Push
      end
    end
  end
end
