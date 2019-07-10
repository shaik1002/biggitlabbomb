# frozen_string_literal: true

class Projects::WikiPagesController < Projects::ApplicationController
  include HasProjectWiki
  include SendsBlob
  include PreviewMarkdown
  include Gitlab::Utils::StrongMemoize
  include EmptyActions
  include RedirectWhen

  attr_accessor :project_wiki, :sidebar_page, :sidebar_wiki_entries
  empty_action :edit

  # Share the templates from the wikis controller.
  def self.local_prefixes
    [controller_path, 'projects/wikis']
  end

  before_action :authorize_create_wiki!, only: [:edit, :create, :update, :history]
  before_action :load_page, only: [:show, :edit, :update, :history, :destroy]
  before_action :authorize_admin_wiki!, only: :destroy
  before_action :valid_encoding?, only: [:show, :edit, :update], if: :load_page
  before_action only: [:edit, :update], unless: :valid_encoding? do
    redirect_to(project_wiki_path(@project, @page))
  end

  redirect_when(:created, :updated) do
    [project_wiki_path(@project, @page), { notice: _('Wiki was successfully updated.') }]
  end

  def show
    if @page
      show_page
    elsif file_blob
      show_blob
    elsif should_create_missing_page?
      create_missing_page
    else
      render 'empty'
    end
  end

  def update
    @page = WikiPages::UpdateService
      .new(@project, current_user, wiki_params)
      .execute(@page)

    return updated! if @page.valid?

    render 'edit'
  rescue WikiPage::PageChangedError, WikiPage::PageRenameError, Gitlab::Git::Wiki::OperationError => e
    @error = e
    render 'edit'
  end

  def create
    @page = WikiPages::CreateService
      .new(@project, current_user, wiki_params)
      .execute

    return created! if @page.persisted?

    render action: "edit"
  rescue Gitlab::Git::Wiki::OperationError => e
    @page = project_wiki.build_page(wiki_params)
    @error = e

    render 'edit'
  end

  def history
    if @page
      @page_versions = Kaminari.paginate_array(@page.versions(page: params[:page].to_i),
                                               total_count: @page.count_versions)
        .page(params[:page])
    else
      redirect_to(
        project_wiki_path(@project, :home),
        notice: _("Page not found")
      )
    end
  end

  def destroy
    WikiPages::DestroyService.new(@project, current_user).execute(@page)

    redirect_to project_wiki_path(@project, :home),
                status: 302,
                notice: _("Page was successfully deleted")
  rescue Gitlab::Git::Wiki::OperationError => e
    @error = e
    render 'edit'
  end

  # Callback for PreviewMarkdown
  def preview_markdown_params
    { pipeline: :wiki, project_wiki: project_wiki, page_slug: params[:id] }
  end

  private

  def show_page
    set_encoding_error unless valid_encoding?

    @page_dir = @project_wiki.find_dir(@page.directory) if @page.directory.present?
    @show_children = true

    render 'show'
  end

  def show_blob
    send_blob(@project_wiki.repository, file_blob)
  end

  def should_create_missing_page?
    view_param = @project_wiki.empty? ? params[:view] : 'create'
    can?(current_user, :create_wiki, @project) && view_param == 'create'
  end

  def create_missing_page
    @page = project_wiki.build_page(title: params[:id])

    render 'edit'
  end

  def wiki_params
    params.require(:wiki_page).permit(:title, :content, :format, :message, :last_commit_sha)
  end

  def load_page
    @page ||= @project_wiki.find_page(*page_params)
  end

  def page_params
    keys = [:id]
    keys << :version_id if params[:action] == 'show'

    params.values_at(*keys)
  end

  def valid_encoding?
    strong_memoize(:valid_encoding) do
      @page.content.encoding == Encoding::UTF_8
    end
  end

  def set_encoding_error
    flash.now[:notice] = _("The content of this page is not encoded in UTF-8. Edits can only be made via the Git repository.")
  end

  def file_blob
    strong_memoize(:file_blob) do
      commit = @project_wiki.repository.commit(@project_wiki.default_branch)

      next unless commit

      @project_wiki.repository.blob_at(commit.id, params[:id])
    end
  end
end
