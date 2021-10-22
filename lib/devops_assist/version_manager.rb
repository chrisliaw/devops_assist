
require 'tty/prompt'

module DevopsAssist
  module VersionManager
    extend DevopsAssist::Gem
    extend TR::VUtils

    def self.prompt_version(gemName, last_version = "0.0.0")

      begin

        last_version = "0.0.0" if is_empty?(last_version)

        pmt = TTY::Prompt.new
        vers = possible_versions(last_version)

        vers << "Custom"
        vers << "Quit"
        #vers << [ \
        #          "Maybe not now..." \
        #          ,"Nah, forget it..." \
        #].sample

        vsel = pmt.select("  Please select one of the versions below:") do |menu|
          vers.each do |v|
            menu.choice v
          end
        end

        case vsel
        when "Custom"
          vsel = pmt.ask("  Please provide custom version no:", required: true) 
        when vers[-1]
          raise DevopsAssist::Error, "  Aborted. Have a nice day! " 
        end

        vsel

      rescue TTY::Reader::InputInterrupt
        raise DevopsAssist::Error
      end
      
    end

  end
end
