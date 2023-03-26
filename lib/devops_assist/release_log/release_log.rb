
require 'toolrack'
require 'yaml'

module DevopsAssist

  class ReleaseLogError < StandardError; end

  class ReleaseLogger
    include TR::CondUtils

    LOG_NAME = ".release_history.yml"
    
    attr_accessor :relRec
    def initialize(rec = nil)
      if not_empty?(rec)
        @relRec = YAML.load(rec)
      end
    end

    def log_release(relName, version, &block)

      raise ReleaseLogError, "Release name cannot be empty" if is_empty?(relName)
      raise ReleaseLogError, "Version cannot be empty" if is_empty?(version)

      #raise ReleaseLogError, "Version '#{version}' already in the log file for release '#{relName}'" if is_version_exist?(version, relName)

      rec = { version: version, timestamp: Time.now.to_f }
      if block
        relBy = block.call(:released_by)
        rec[:released_by] = relBy if not_empty?(relBy)

        relFrom = block.call(:released_location)
        rec[:released_location] = relFrom if not_empty?(relFrom)
      end

      relRec[relName] = [] if is_empty?(relRec[relName])
      relRec[relName] << rec

      save

      relRec
    end

    def last_version_number(relName = nil)
      if is_empty?(relName)
        list = relRec[relRec.keys.first]
      else
        list = relRec[relName]
      end

      list.last[:version] if not_empty?(list)
    end

    def is_version_exist?(ver, relName = nil)
      if is_empty?(relName)
        list = relRec[relRec.keys.first]
      else
        list = relRec[relName]
      end
      res = false
      if not_empty?(list)
        ref = ::Gem::Version.new(ver)
        list.each do |l|
          subj = ::Gem::Version.new(l[:version])
          res = (subj == ref)
          break if res
        end
      end

      res
    end

    def releases(&block)
      ret = Marshal.load(Marshal.dump(relRec))
      ret.values.each do |v|
      #ret.map { |k,v|
        v.map { |r|

          t = r[:timestamp]
          tt = Time.at(t)

          res = nil

          if block
            res = block.call(:convert_timestamp, tt)
          end

          if is_empty?(res)
            res = tt.strftime("%a, %d %b %Y, %H:%M:%S")
          end

          r[:timestamp] = res 

          relBy = r[:released_by]
          if not_empty?(relBy) 

            if block
              res = block.call(:convert_released_by, relBy)
              r[:released_by] = res if not_empty?(res)
            end

          end

          relFrom = r[:released_location]
          if not_empty?(relFrom) 

            if block
              res = block.call(:convert_released_location, relFrom)
              r[:released_location] = res if not_empty?(res)
            end

          end

          r

        }

        v

      end

      ret
    end

    def self.load(root = Dir.getwd)
      f = File.join(root, LOG_NAME) 
      if not File.exist?(f)
        ReleaseLogger.new
      else
        relLog = nil
        File.open(f,"r") do |ff|
          relLog = ReleaseLogger.new(ff.read)
        end
        relLog
      end
    end

    def save(root = Dir.getwd)
      f = File.join(root, LOG_NAME)
      File.open(f,"w") do |ff|
        ff.write YAML.dump(relRec)
      end
    end

    def reset_log(root = Dir.getwd)
      log = File.join(root, LOG_NAME)
      FileUtils.rm(log) if File.exist?(log)
    end

    private
    def relRec
      if @relRec.nil?
        @relRec = { }
      end
      @relRec
    end



  end
end


