# frozen_string_literal: true

class Groups::BoardsController < Groups::ApplicationController
  include BoardsActions
  include RecordUserLastActivity
  include Gitlab::Utils::StrongMemoize

  before_action do
    push_frontend_feature_flag(:board_multi_select, group)
    push_frontend_feature_flag(:display_work_item_epic_issue_sidebar, group)
    experiment(:prominent_create_board_btn, subject: current_user) do |e|
      e.control {}
      e.candidate {}
    end.run
  end

  feature_category :team_planning
  urgency :low

  private

  def board_finder
    Boards::BoardsFinder.new(parent, current_user, board_id: params[:id])
  end
  strong_memoize_attr :board_finder

  def board_create_service
    Boards::CreateService.new(parent, current_user)
  end
  strong_memoize_attr :board_create_service

  def authorize_read_board!
    access_denied! unless can?(current_user, :read_issue_board, group)
  end
end

Groups::BoardsController.prepend_mod
