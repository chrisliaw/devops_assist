

require_relative '../lib/devops_assist'
require 'tty/prompt'

include DevopsAssist

namespace :devops do

  desc "Initialize the directory"
  task :init do

    root = Dir.getwd

    gu = GemUtils.new(root)

    begin

      pmt = TTY::Prompt.new

      pmt.puts "\n\n DevopsAssist version #{DevopsAssist::VERSION}"
      pmt.puts " Initialization of workspace"
      pmt.puts


    rescue TTY::Reader::InputInterrupt
    rescue Exception => ex
      pmt.puts "\n Aborted"
    end

  end

  desc "Release gem file project"
  task :release do
 
    root = Dir.getwd
    gu = GemUtils.new(root)
    begin

      ws = Gvcs::Workspace.new(root)
      raise DevopsAssist::Error, "Given path '#{root}' is not a git workspace" if not ws.is_workspace?

      pmt = TTY::Prompt.new

      # let's mark the session to allow automated context switching
      ENV[DevopsAssist::EnvKeyGemReleasing] = "true"

      gemName = gu.gem_name

      pmt.say "  Starting gem release for gem #{gemName}", color: :yellow

      # select version 
      #ver = DevopsAssist::VersionManager.prompt_version(gemName, rl.last_version_number(gemName))
      ver = DevopsAssist::VersionManager.prompt_version(gemName, gu.gem_version_string)
      pmt.say "  Version '#{ver}' is chosen\n", color: :yellow

      selVerFile = gu.update_gem_version(ver) do |*args|
        ops = args.first
        case ops
        when :select_version_file
          files = args[1]
          vfile = pmt.select("Please select one of the gem version file to update the version number:", files)
          vfile
        end
      end
      pmt.say "  Version file updated", color: :yellow

      # Add file changed by system into git first
      miscFiles = []
      miscFiles << selVerFile  # version.rb
      miscFiles << DevopsAssist::ReleaseLogger::LOG_NAME  # release_history.yml
      #miscFiles << 'Gemfile.lock'
      Rake::Task["devops:vcs:checkin_misc_files"].execute({ root: root, files: miscFiles, version: ver, workspace: ws, pmt: pmt })
      #pmt.say "  Updated files during release prep have committed into version control", color: :yellow


      # check in source code
      # Check in must be done 1st or else the 'gem build' process will fail
      # because build will use git command. For any files that already deleted,
      # the build will failed to find the files and throw exception
      # However, there are files that will changed after build i.e Gemfile.lock
      res = Rake::Task["devops:vcs:checkin_changes"].execute
      pmt.say "  Workspace check in done\n\n", color: :yellow

      proceed = pmt.yes?(" Proceed to build the gem? ", color: :yellow) 
      #raise GitCliPrompt::UserAborted if not proceed

      if proceed

        # test build the gem, make sure there is no error
        # If error expected the scripts stops here
        Rake::Task["build"].execute

        # Record the version number in the log files 
        # for reporting traceability
        rl = DevopsAssist::ReleaseLogger.load
        rl.log_release(gemName, ver)
        #pmt.say "  Release version number is logged after successful test built", color: :yellow

        ## If successfully built, following files shall be changed
        #miscFiles = []
        #miscFiles << selVerFile  # version.rb
        #miscFiles << DevopsAssist::ReleaseLogger::LOG_NAME  # release_history.yml
        #miscFiles << 'Gemfile.lock'
        #Rake::Task["devops:vcs:checkin_misc_files"].execute({ root: root, files: miscFiles, version: ver })
        #pmt.say "  Updated files during release prep have committed into version control", color: :yellow

        ## check in source code
        #res = Rake::Task["devops:vcs:checkin_changes"].execute
        #pmt.say "  Workspace check in done\n", color: :yellow

        #proceed = pmt.yes?(" Proceed with release? ") 
        #raise GitCliPrompt::UserAborted if not proceed

        # 
        # Actual building the real gems build the gem
        # Any possible reasons here error but not the one above?
        #
        # Main reason to do double build is to avoid to generate
        # 2 log entries in Git for each build, which the 2nd (latest) 
        # log is just about the version updates (version pre 0.4.x way)
        #
        #Rake::Task["build"].execute

        #rl.log_release(gemName, ver)
        #pmt.say "  Release version number is logged", color: :yellow

        # publish gem
        Rake::Task["devops:gem:publish_gem"].execute({ version: ver, pmt: pmt })

      end

      # following files shall change when gem is built
      #miscFiles = []
      #miscFiles << selVerFile
      #miscFiles << DevopsAssist::ReleaseLogger::LOG_NAME
      #miscFiles << 'Gemfile.lock'
      #Rake::Task["devops:vcs:checkin_misc_files"].execute({ root: root, files: miscFiles, version: ver })
      #pmt.say "  Updated files during release prep have committed into version control", color: :yellow

      Rake::Task["devops:vcs:tag_source_code"].execute({ root: root, version: ver, workspace: ws, pmt: pmt })
      pmt.say "  Source code is tagged as version #{ver}", color: :yellow

      Rake::Task["devops:vcs:push_source_code"].execute({ root: root, pmt: pmt })

      install = pmt.yes?(" Install the released gem to local environment? ")
      if install
        STDOUT.puts `gem install pkg/#{gemName}-#{ver}.gem`
      else
        pmt.say "\n\n Please run the gem install command manually : \n gem install pkg/#{gemName}-#{ver}.gem", color: :yellow
      end

      pmt.say " Gem #{gemName} version #{ver} released successfully ", color: :green

    rescue GitCliPrompt::UserAborted, GitCliPrompt::UserChangedMind, TTY::Reader::InputInterrupt
      STDOUT.puts
    rescue Exception => ex
      STDERR.puts ex.message
      STDOUT.puts "\n\nAborted\n"
      #STDERR.puts ex.backtrace.join('\n')
    end

  end

end

