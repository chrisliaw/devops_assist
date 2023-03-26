
require_relative '../lib/devops_assist'

require 'tty/prompt'

#include DevopsAssist::Gem
include TR::VUtils

namespace :devops do
  namespace :gem do

    desc "Build the gem"
    task :build_gem, :version do |t, args|

      root = Dir.getwd

      gu = GemUtils.new(root)

      selVerFile = gu.update_gem_version(args) do |*args|
        ops = args.first
        case ops
        when :select_version_file
          files = args[1]
          vfile = pmt.select("  Please select one of the gem version file to update the version number:", files)
          vfile
        end
      end

      Rake::Task["build"].execute

    end

    desc "Publish specific gem version to Rubygems"
    task :publish_gem, :version do |t, args|

      pmt = args[:pmt]
      version = args[:version]

      ans = pmt.yes?("  Proceed to publish the gem to Rubygems?")
      if ans
        res, tg, out = publish_gem(version) do |*args|
          ops = args.first
          case ops
          when :multiple_rubygems_account
            acct = args[1]
            selAct = pmt.select("  Please select one of the Rubygems credential to release:") do |menu|
              
              acct.each do |k,v|
                menu.choice k, k
              end

              menu.choice "Skip", :skip
              menu.choice "Quit", :quit

            end
            
            raise DevopsAssist::Error, " Aborted. Have a nice day " if selAct == :quit

            selAct
          end
        end

        pmt.say("  Gem publishing is skipped", color: :yellow) if res == :skipped

        if res.respond_to?(:success?)
          if res.success?
            pmt.say "  Gem published!\n", color: :yellow
          else
            pmt.say "  Gem publishing failed. Return message :\n#{out}", color: :red
          end
        end

      end

    end

    desc "Publish specific gem file to Rubygems"
    task :publish_gem_file, :file do |t, args|

    end

  end
end
