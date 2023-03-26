
require 'yaml'

module DevopsAssist
  class GemUtils
    include TR::CondUtils

    class GemUtilsError < StandardError; end

    def initialize(gemRoot)
      @root = gemRoot
    end

    def update_gem_version(newVersion, &block)

      version_file = find_gem_version_file

      if version_file.length > 1
        if block
          selVerFile = block.call(:select_version_file, version_file)
          raise GemError, "Multiple version files found (#{version_file.join(", ")}) and user not selected any" if is_empty?(selVerFile)
        else
          raise GemError, "Multiple version files found (#{version_file.join(", ")}). Please provide a block to select version file or make sure there is no other file named version.rb"
        end
      else
        selVerFile = version_file.first
      end

      tmpFile = File.join(File.dirname(selVerFile),"version-da.bak")
      FileUtils.mv(selVerFile,tmpFile)

      File.open(selVerFile,"w") do |f|
        File.open(tmpFile,"r").each_line do |l|
          if l =~ /VERSION/
            indx = (l =~ /=/)
            ll = "#{l[0..indx]} \"#{newVersion}\""
            f.puts ll
          else
            f.write l
          end
        end
      end

      FileUtils.rm(tmpFile)

      selVerFile

    end

    def find_gem_version_file
      raise GemUtilsError, "Root path '#{@root}' to find_gem_version_file is empty" if is_empty?(@root)
      Dir.glob(File.join(@root,"**/version.rb"))
    end

    def self.publish_gem(version, opts = { }, &block)

      cred = find_rubygems_api_key

      selAcct = cred.keys.first
      if cred.keys.length > 1
        logger.tdebug :pubgem, "Multiple rubygems account detected."
        # multiple account configured...
        selAcct = block.call(:multiple_rubygems_account, cred)
        return :skipped if selAcct == :skip
        raise GemError, "No rubygems account is selected." if is_empty?(selAcct)
      end

      # find the package
      root = opts[:root] || Dir.getwd
      foundGem = Dir.glob("**/*-#{version}*.gem")
      if foundGem.length == 0
        raise GemError, "No built gem found."
      elsif foundGem.length > 1
        if block
          targetGem = block.call(:multiple_built_gems, foundGem)
        else
          raise GemError, "Multiple versions of gem found : #{foundGem}. Please provide a block for selection"
        end
      else
        targetGem = foundGem.first
      end

      cmd = "cd #{root} && gem push #{targetGem} -k #{selAcct}"
      logger.tdebug :pubgem, "Command to publish gem : #{cmd}"  
      res = `#{cmd}`
      [$?, targetGem, res]

    end

    def publish_gem_file(gemfile, opts = { }, &block)

      cred = find_rubygems_api_key

      selAcct = cred.keys.first
      if cred.keys.length > 1
        logger.tdebug :pubgemfile, "Multiple rubygems account detected."
        # multiple account configured...
        selAcct = block.call(:multiple_rubygems_account, cred)
        raise GemError, "No rubygems account is selected." if is_empty?(selAcct)
      end

      if File.exist?(gemfile)
        root = File.dirname(gemfile)
        targetGem = File.basename(gemfile)

        cmd = "cd #{root} && gem push #{targetGem} -k #{selAcct}"
        logger.tdebug :pubgemfile, "Command to publish gem : #{cmd}"  
        res = `#{cmd}`
        [$?, res, targetGem]
      else
        raise GemError, "Given Gemfile '#{gemfile}' not found"
      end

    end

    def gem_name
      gemspec.name
    end

    def gem_version_string
      gem_version.version
    end

    def gem_version
      gemspec.version
    end

    def gemspec
      raise GemUtilsError, "Root path is not given" if is_empty?(@root)

      if @_gemSpec.nil?
        @_gemSpec = ::Gem::Specification.load(Dir.glob(File.join(@root,"*.gemspec")).first)
        raise GemUtilsError, "Cannot find gemspec from #{@root}" if @_gemSpec.nil?
      end

      @_gemSpec
    end

    private
    def logger
      if @logger.nil?
        @logger = TeLogger::Tlogger.new
        @logger.tag = :gem_utils
      end
      @logger
    end

    def find_rubygems_api_key
      if TR::RTUtils.on_windows?
        credFile = File.join(ENV['USERPROFILE'],".gem","credentials")
      else
        credFile = File.join(Dir.home,".local","share","gem","credentials")
      end

      raise GemError, "Credential file not found at '#{credFile}'" if not File.exist?(credFile)

      cred = nil
      File.open(credFile,"r") do |f|
        cred = YAML.load(f.read)
      end

      raise GemError, "Credential file is empty" if is_empty?(cred)
      raise GemError, "No credential created yet for rubygems." if is_empty?(cred.keys)

      cred
    end

    

  end
end
