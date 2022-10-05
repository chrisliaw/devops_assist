

require_relative '../lib/devops_assist'
require 'tty/prompt'

namespace :devops do

  desc "Release gem file project"
  task :release do
 
    begin

      pmt = TTY::Prompt.new

      root = Dir.getwd

      # let's mark the session to allow automated context switching
      ENV[DevopsAssist::EnvKeyGemReleasing] = "true"

      gemName = find_gem_name(root)

      pmt.say "  Starting gem release for gem #{gemName}", color: :yellow

      # check in source code
      res = Rake::Task["devops:vcs:checkin_changes"].execute
      pmt.say "  Workspace check in done\n", color: :yellow

      proceed = pmt.yes?(" Proceed with release? ") 
      raise GitCliPrompt::UserAborted if not proceed

      rl = DevopsAssist::ReleaseLogger.load

      # select version
      ver = DevopsAssist::VersionManager.prompt_version(gemName, rl.last_version_number(gemName))
      pmt.say "  Version no. '#{ver}' chosen", color: :yellow

      selVerFile = update_gem_version(root, ver) do |*args|
        ops = args.first
        case ops
        when :select_version_file
          files = args[1]
          vfile = pmt.select("Please select one of the gem version file to update the version number:", files)
          vfile
        end
      end
      pmt.say "  Version file updated", color: :yellow

      # build the gem
      Rake::Task["build"].execute

      rl.log_release(gemName, ver)
      pmt.say "  Release version number is logged", color: :yellow

      # publish gem
      Rake::Task["devops:gem:publish_gem"].execute({ version: ver, pmt: pmt })

      # following files shall change when gem is built
      miscFiles = []
      miscFiles << selVerFile
      miscFiles << DevopsAssist::ReleaseLogger::LOG_NAME
      miscFiles << 'Gemfile.lock'
      Rake::Task["devops:vcs:checkin_misc_files"].execute({ root: root, files: miscFiles, version: ver })
      pmt.say "  Updated files during release prep have committed into version control", color: :yellow

      Rake::Task["devops:vcs:tag_source_code"].execute({ root: root, version: ver })
      pmt.say "  Source code is tagged as version #{ver}", color: :yellow

      Rake::Task["devops:vcs:push_source_code"].execute({ root: root, pmt: pmt })

    rescue GitCliPrompt::UserAborted, GitCliPrompt::UserChangedMind
    rescue Exception => ex
      STDERR.puts ex.message
      STDOUT.puts "\n\nAborted\n"
      #STDERR.puts ex.backtrace.join('\n')
    end

  end

end

