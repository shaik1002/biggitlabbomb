# frozen_string_literal: true

module Projects
  class LabelCreationFacade
    include ActiveModel::API

    attr_accessor :project

    def call
      Label.templates.each do |label|
        # slice on column_names to ensure an added DB column will not break a mixed deployment
        params = label.attributes.slice(*Label.column_names).except('id', 'template', 'created_at', 'updated_at',
          'type')
        Labels::FindOrCreateService.new(nil, project, params).execute(skip_authorization: true)
      end
    end
  end
end
