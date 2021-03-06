module Fastlane
  module Actions
    module SharedValues
      BACKUP_XCARCHIVE_FILE = :BACKUP_XCARCHIVE_FILE
    end

    class BackupXcarchiveAction < Action
      require 'fileutils'

      def self.run(params)
        # Get params
        xcarchive = params[:xcarchive]
        base_destination = params[:destination]
        zipped = params[:zip]
        versioned = params[:versioned]
        
        # Prepare destionation folder
        full_destination = base_destination

        if versioned
          date = Time.now.strftime("%Y-%m-%d")
          version = `agvtool what-marketing-version -terse1`
          subfolder = "#{date} #{version.strip}"
          full_destination = File.expand_path(subfolder, base_destination)
        end

        FileUtils.mkdir(full_destination) unless File.exists?(full_destination)

        # Save archive to destination
        if zipped 
          Helper.log.info "Compressing #{xcarchive}"

          xcarchive_folder = File.expand_path(File.dirname(xcarchive))
          xcarchive_file = File.basename(xcarchive)
          zip_file = File.expand_path(File.join("#{xcarchive_file}.zip"))

          # Create zip
          Actions.sh(%Q[cd "#{xcarchive_folder}" && zip -r -X "#{zip_file}" "#{xcarchive_file}" > /dev/null])

          # Moved to its final destination
          FileUtils.mv(zip_file, full_destination)

          Actions.lane_context[SharedValues::BACKUP_XCARCHIVE_FILE] = "#{full_destination}/#{File.basename(zip_file)}"
        else
          # Copy xcarchive file
          FileUtils.cp_r(xcarchive, full_destination)

          Actions.lane_context[SharedValues::BACKUP_XCARCHIVE_FILE] = "#{full_destination}/#{File.basename(xcarchive)}"
        end

      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Save your [zipped] xcarchive elsewhere from default path"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :xcarchive,
                                       description: 'Path to your xcarchive file. Optional if you use the `xcodebuild` action',
                                       default_value: Actions.lane_context[SharedValues::XCODEBUILD_ARCHIVE],
                                       optional: false,
                                       env_name: 'BACKUP_XCARCHIVE_ARCHIVE',
                                       verify_block: Proc.new do |value|
                                        raise "Couldn't find xcarchive file at path '#{value}'".red if !Helper.test? && !File.exists?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :destination,
                                       description: 'Where your archive will be placed',
                                       optional: false,
                                       env_name: 'BACKUP_XCARCHIVE_DESTINATION',
                                       verify_block: Proc.new do |value|
                                        raise "Couldn't find the destination folder at '#{value}'".red if !Helper.test? && !File.directory?(value) && !File.exists?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :zip,
                                       description: 'Enable compression of the archive. Default value `true`',
                                       is_string: false,
                                       default_value: true,
                                       optional: true,
                                       env_name: 'BACKUP_XCARCHIVE_ZIP'),
          FastlaneCore::ConfigItem.new(key: :versioned,
                                       description: 'Create a versioned (date and app version) subfolder where to put the archive. Default value `true`',
                                       is_string: false,
                                       default_value: true,
                                       optional: true,
                                       env_name: 'BACKUP_XCARCHIVE_VERSIONED')
        ]
      end

      def self.output
        [
          ['BACKUP_XCARCHIVE_FILE', 'Path to your saved xcarchive (compressed) file']
        ]
      end

      def self.author
        ['dral3x']
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?platform
      end
      
    end
  end
end