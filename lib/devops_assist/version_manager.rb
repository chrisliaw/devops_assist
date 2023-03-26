
require 'tty/prompt'

module DevopsAssist
  module VersionManager
    extend TR::VUtils

    def self.prompt_version(gemName, last_version = "0.1.0")

      #begin

        last_version = "0.1.0" if is_empty?(last_version)

        pmt = TTY::Prompt.new
        vers = possible_versions(last_version)

        vv = []
        vv << vers[2]
        vv << vers[1]
        vv << vers[0]

        vv << "Custom"
        vv << "Quit"
        #vers << [ \
        #          "Maybe not now..." \
        #          ,"Nah, forget it..." \
        #].sample

        vsel = pmt.select("  Please select one of the versions below:") do |menu|
          menu.choice "#{last_version} (current version - no change in version)", :no_change
          #vers.each do |v|
          vv.each do |v|
            menu.choice v
          end
        end

        case vsel
        when :no_change
          vsel = last_version
        when "Custom"
          vsel = pmt.ask("  Please provide custom version no:", required: true) 
        when vv[-1]
          raise DevopsAssist::Error, "  Aborted. Have a nice day! " 
        end

        vsel

      #rescue TTY::Reader::InputInterrupt
      #  raise DevopsAssist::Error
      #end
      
    end

  end
end
