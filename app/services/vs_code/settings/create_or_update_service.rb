# frozen_string_literal: true

module VsCode
  module Settings
    class CreateOrUpdateService
      def initialize(current_user:, settings_context_hash: nil, params: {})
        @current_user = current_user
        @settings_context_hash = settings_context_hash
        @params = params
      end

      def execute
        # The GitLab VSCode settings API does not support creating or updating
        # machines.
        return ServiceResponse.success(payload: DEFAULT_MACHINE) if params[:setting_type] == 'machines'

        setting = VsCodeSetting.by_user(current_user)

        if params[:setting_type] == 'extensions'
          setting = setting.by_setting_types(['extensions'], settings_context_hash).first
          return create_or_update(setting: setting, create_params: { settings_context_hash: settings_context_hash })
        end

        setting = setting.by_setting_types([params[:setting_type]]).first
        create_or_update(setting: setting, update_params: { uuid: SecureRandom.uuid })
      end

      private

      def create_or_update(setting:, create_params: {}, update_params: {})
        if setting.nil?
          attributes = params.merge(user: current_user, uuid: SecureRandom.uuid, **create_params)
          setting = VsCodeSetting.new(attributes)
        else
          setting.assign_attributes(content: params[:content], **update_params)
        end

        if setting.save
          ServiceResponse.success(payload: setting)
        else
          ServiceResponse.error(
            message: setting.errors.full_messages.to_sentence,
            payload: { setting: setting }
          )
        end
      end

      attr_reader :current_user, :settings_context_hash, :params
    end
  end
end
