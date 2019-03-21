# frozen_string_literal: true

module Projects
  module HashedStorage
    AttachmentMigrationError = Class.new(StandardError)

    AttachmentCannotMoveError = Class.new(StandardError)

    class BaseAttachmentService < BaseService
      # Returns the disk_path value before the execution
      attr_reader :old_disk_path

      # Returns the disk_path value after the execution
      attr_reader :new_disk_path

      # Returns the logger currently in use
      attr_reader :logger

      # Return whether this operation was skipped or not
      #
      # @return [Boolean] true if skipped of false otherwise
      def skipped?
        @skipped
      end

      protected

      def move_folder!(old_path, new_path)
        unless File.directory?(old_path)
          logger.info(_("Skipped attachments move from '%{old_path}' to '%{new_path}', source path doesn't exist or is not a directory (PROJECT_ID=%{project_id})") % { old_path: old_path, new_path: new_path, project_id: project.id })
          @skipped = true

          return true
        end

        if File.exist?(new_path)
          logger.error(_("Cannot move attachments from '%{old_path}' to '%{new_path}', target path already exist (PROJECT_ID=%{project_id})") % { old_path: old_path, new_path: new_path, project_id: project.id })
          raise AttachmentCannotMoveError, _("Target path '%{new_path}' already exists") % { new_path: new_path }
        end

        # Create base path folder on the new storage layout
        FileUtils.mkdir_p(File.dirname(new_path))

        FileUtils.mv(old_path, new_path)
        logger.info(_("Project attachments moved from '%{old_path}' to '%{new_path}' (PROJECT_ID=%{project_id})") % { old_path: old_path, new_path: new_path, project_id: project.id })

        true
      end
    end
  end
end
