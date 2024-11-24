# frozen_string_literal: true

module API
  module Ci
    module Helpers
      module RequestHelpers
        def get_caller_info
          {
            endpoint: method_name,
            user_agent: headers['User-Agent']
          }
        end
      end
    end
  end
end
