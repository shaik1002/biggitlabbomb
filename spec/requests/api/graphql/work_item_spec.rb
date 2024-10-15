# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.work_item(id)', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, :private, group: group) }
  let_it_be(:developer) { create(:user, developer_of: group) }
  let_it_be(:guest) { create(:user, guest_of: group) }
  let_it_be(:work_item) do
    create(
      :work_item,
      project: project,
      description: '- List item',
      start_date: Date.today,
      due_date: 1.week.from_now,
      created_at: 1.week.ago,
      last_edited_at: 1.day.ago,
      last_edited_by: guest
    )
  end

  let_it_be(:child_item1) { create(:work_item, :task, project: project) }
  let_it_be(:child_item2) { create(:work_item, :task, confidential: true, project: project) }
  let_it_be(:child_link1) { create(:parent_link, work_item_parent: work_item, work_item: child_item1) }
  let_it_be(:child_link2) { create(:parent_link, work_item_parent: work_item, work_item: child_item2) }

  let(:current_user) { developer }
  let(:work_item_data) { graphql_data['workItem'] }
  let(:work_item_fields) { all_graphql_fields_for('WorkItem', max_depth: 2) }
  let(:global_id) { work_item.to_gid.to_s }

  let(:query) do
    graphql_query_for('workItem', { 'id' => global_id }, work_item_fields)
  end

  context 'when project is archived' do
    before do
      project.update!(archived: true)
      post_graphql(query, current_user: current_user)
    end

    it 'returns the correct value in the archived field' do
      expect(work_item_data).to include(
        'id' => work_item.to_gid.to_s,
        'iid' => work_item.iid.to_s,
        'archived' => true
      )
    end
  end

  context 'when the user can read the work item' do
    let(:incoming_email_token) { current_user.incoming_email_token }
    let(:work_item_email) do
      "p+#{project.full_path_slug}-#{project.project_id}-#{incoming_email_token}-issue-#{work_item.iid}@gl.ab"
    end

    before do
      stub_incoming_email_setting(enabled: true, address: "p+%{key}@gl.ab")
      post_graphql(query, current_user: current_user)
    end

    it_behaves_like 'a working graphql query'

    it 'returns all fields' do
      expect(work_item_data).to include(
        'description' => work_item.description,
        'id' => work_item.to_gid.to_s,
        'iid' => work_item.iid.to_s,
        'lockVersion' => work_item.lock_version,
        'state' => "OPEN",
        'title' => work_item.title,
        'confidential' => work_item.confidential,
        'workItemType' => hash_including('id' => work_item.work_item_type.to_gid.to_s),
        'reference' => work_item.to_reference,
        'createNoteEmail' => work_item_email,
        'archived' => false,
        'userPermissions' => {
          'readWorkItem' => true,
          'updateWorkItem' => true,
          'deleteWorkItem' => false,
          'adminWorkItem' => true,
          'adminParentLink' => true,
          'setWorkItemMetadata' => true,
          'createNote' => true,
          'adminWorkItemLink' => true
        },
        'project' => hash_including('id' => project.to_gid.to_s, 'fullPath' => project.full_path)
      )
    end

    context 'when work item is created at the group level' do
      let_it_be(:group_work_item) { create(:work_item, :group_level, namespace: group) }
      let(:global_id) { group_work_item.to_gid.to_s }

      it 'always returns false in the archived field' do
        expect(work_item_data).to include(
          'id' => group_work_item.to_gid.to_s,
          'iid' => group_work_item.iid.to_s,
          'archived' => false
        )
      end
    end

    context 'when querying work item type information' do
      include_context 'with work item types request context'

      let(:work_item_fields) { "workItemType { #{work_item_type_fields} }" }

      it 'returns work item type information' do
        expect(work_item_data['workItemType']).to match(
          expected_work_item_type_response(work_item.resource_parent, work_item.work_item_type).first
        )
      end
    end

    context 'when querying widgets' do
      describe 'description widget' do
        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetDescription {
                description
                descriptionHtml
                edited
                lastEditedBy {
                  webPath
                  username
                }
                lastEditedAt
              }
            }
          GRAPHQL
        end

        it 'returns widget information' do
          expect(work_item_data).to include(
            'id' => work_item.to_gid.to_s,
            'widgets' => include(
              hash_including(
                'type' => 'DESCRIPTION',
                'description' => work_item.description,
                'descriptionHtml' => ::MarkupHelper.markdown_field(work_item, :description, {}),
                'edited' => true,
                'lastEditedAt' => work_item.last_edited_at.iso8601,
                'lastEditedBy' => {
                  'webPath' => "/#{guest.full_path}",
                  'username' => guest.username
                }
              )
            )
          )
        end
      end

      describe 'hierarchy widget' do
        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetHierarchy {
                parent {
                  id
                }
                children {
                  nodes {
                    id
                  }
                }
                hasChildren
              }
            }
          GRAPHQL
        end

        it 'returns widget information' do
          expect(work_item_data).to include(
            'id' => work_item.to_gid.to_s,
            'widgets' => include(
              hash_including(
                'type' => 'HIERARCHY',
                'parent' => nil,
                'children' => { 'nodes' => match_array(
                  [
                    hash_including('id' => child_link1.work_item.to_gid.to_s),
                    hash_including('id' => child_link2.work_item.to_gid.to_s)
                  ]) },
                'hasChildren' => true
              )
            )
          )
        end

        it 'avoids N+1 queries' do
          post_graphql(query, current_user: current_user) # warm up

          control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
            post_graphql(query, current_user: current_user)
          end

          create_list(:parent_link, 3, work_item_parent: work_item)

          expect do
            post_graphql(query, current_user: current_user)
          end.not_to exceed_all_query_limit(control)
        end

        context 'when user is guest' do
          let(:current_user) { guest }

          it 'filters out not accessible children or parent' do
            expect(work_item_data).to include(
              'id' => work_item.to_gid.to_s,
              'widgets' => include(
                hash_including(
                  'type' => 'HIERARCHY',
                  'parent' => nil,
                  'children' => { 'nodes' => match_array(
                    [
                      hash_including('id' => child_link1.work_item.to_gid.to_s)
                    ]) },
                  'hasChildren' => true
                )
              )
            )
          end
        end

        context 'when requesting child item' do
          let_it_be(:work_item) { create(:work_item, :task, project: project, description: '- List item') }
          let_it_be(:parent_link) { create(:parent_link, work_item: work_item) }

          it 'returns parent information' do
            expect(work_item_data).to include(
              'id' => work_item.to_gid.to_s,
              'widgets' => include(
                hash_including(
                  'type' => 'HIERARCHY',
                  'parent' => hash_including('id' => parent_link.work_item_parent.to_gid.to_s),
                  'children' => { 'nodes' => match_array([]) },
                  'hasChildren' => false
                )
              )
            )
          end
        end

        context 'when ordered by default by created_at' do
          let_it_be(:newest_child) { create(:work_item, :task, project: project, created_at: 5.minutes.from_now) }
          let_it_be(:oldest_child) { create(:work_item, :task, project: project, created_at: 5.minutes.ago) }
          let_it_be(:newest_link) { create(:parent_link, work_item_parent: work_item, work_item: newest_child) }
          let_it_be(:oldest_link) { create(:parent_link, work_item_parent: work_item, work_item: oldest_child) }

          let(:hierarchy_widget) { work_item_data['widgets'].find { |widget| widget['type'] == 'HIERARCHY' } }
          let(:hierarchy_children) { hierarchy_widget['children']['nodes'] }

          it 'places the oldest child item to the beginning of the children list' do
            expect(hierarchy_children.first['id']).to eq(oldest_child.to_gid.to_s)
          end

          it 'places the newest child item to the end of the children list' do
            expect(hierarchy_children.last['id']).to eq(newest_child.to_gid.to_s)
          end

          context 'when relative position is set' do
            let_it_be(:first_child) { create(:work_item, :task, project: project, created_at: 5.minutes.from_now) }

            let_it_be(:first_link) do
              create(:parent_link, work_item_parent: work_item, work_item: first_child, relative_position: 1)
            end

            it 'places children according to relative_position at the beginning of the children list' do
              ordered_list = [first_child, oldest_child, child_item1, child_item2, newest_child]

              expect(hierarchy_children.pluck('id')).to eq(ordered_list.map(&:to_gid).map(&:to_s))
            end
          end
        end
      end

      describe 'assignees widget' do
        let(:assignees) { create_list(:user, 2) }
        let(:work_item) { create(:work_item, project: project, assignees: assignees) }

        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetAssignees {
                allowsMultipleAssignees
                canInviteMembers
                assignees {
                  nodes {
                    id
                    username
                  }
                }
              }
            }
          GRAPHQL
        end

        it 'returns widget information' do
          expect(work_item_data).to include(
            'id' => work_item.to_gid.to_s,
            'widgets' => include(
              hash_including(
                'type' => 'ASSIGNEES',
                'allowsMultipleAssignees' => boolean,
                'canInviteMembers' => boolean,
                'assignees' => {
                  'nodes' => match_array(
                    assignees.map { |a| { 'id' => a.to_gid.to_s, 'username' => a.username } }
                  )
                }
              )
            )
          )
        end
      end

      describe 'labels widget' do
        let(:labels) { create_list(:label, 2, project: project) }
        let(:work_item) { create(:work_item, project: project, labels: labels) }

        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetLabels {
                labels {
                  nodes {
                    id
                    title
                  }
                }
              }
            }
          GRAPHQL
        end

        it 'returns widget information' do
          expect(work_item_data).to include(
            'id' => work_item.to_gid.to_s,
            'widgets' => include(
              hash_including(
                'type' => 'LABELS',
                'labels' => {
                  'nodes' => match_array(
                    labels.map { |a| { 'id' => a.to_gid.to_s, 'title' => a.title } }
                  )
                }
              )
            )
          )
        end
      end

      describe 'start and due date widget' do
        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetStartAndDueDate {
                startDate
                dueDate
              }
            }
          GRAPHQL
        end

        it 'returns widget information' do
          expect(work_item_data).to include(
            'id' => work_item.to_gid.to_s,
            'widgets' => include(
              hash_including(
                'type' => 'START_AND_DUE_DATE',
                'startDate' => work_item.start_date.to_s,
                'dueDate' => work_item.due_date.to_s
              )
            )
          )
        end
      end

      describe 'milestone widget' do
        let_it_be(:milestone) { create(:milestone, project: project) }

        let(:work_item) { create(:work_item, project: project, milestone: milestone) }

        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetMilestone {
                milestone {
                  id
                }
              }
            }
          GRAPHQL
        end

        it 'returns widget information' do
          expect(work_item_data).to include(
            'id' => work_item.to_gid.to_s,
            'widgets' => include(
              hash_including(
                'type' => 'MILESTONE',
                'milestone' => {
                  'id' => work_item.milestone.to_gid.to_s
                }
              )
            )
          )
        end
      end

      describe 'notifications widget' do
        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetNotifications {
                subscribed
              }
            }
          GRAPHQL
        end

        it 'returns widget information' do
          expect(work_item_data).to include(
            'id' => work_item.to_gid.to_s,
            'widgets' => include(
              hash_including(
                'type' => 'NOTIFICATIONS',
                'subscribed' => work_item.subscribed?(current_user, project)
              )
            )
          )
        end
      end

      describe 'currentUserTodos widget' do
        let_it_be(:current_user) { developer }
        let_it_be(:other_todo) { create(:todo, state: :pending, user: current_user) }

        let_it_be(:done_todo) do
          create(:todo, state: :done, target: work_item, target_type: work_item.class.name, user: current_user)
        end

        let_it_be(:pending_todo) do
          create(:todo, state: :pending, target: work_item, target_type: work_item.class.name, user: current_user)
        end

        let_it_be(:other_user_todo) do
          create(:todo, state: :pending, target: work_item, target_type: work_item.class.name, user: create(:user))
        end

        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetCurrentUserTodos {
                currentUserTodos {
                  nodes {
                    id
                    state
                  }
                }
              }
            }
          GRAPHQL
        end

        context 'with access' do
          it 'returns widget information' do
            expect(work_item_data).to include(
              'id' => work_item.to_gid.to_s,
              'widgets' => include(
                hash_including(
                  'type' => 'CURRENT_USER_TODOS',
                  'currentUserTodos' => {
                    'nodes' => match_array(
                      [done_todo, pending_todo].map { |t| { 'id' => t.to_gid.to_s, 'state' => t.state } }
                    )
                  }
                )
              )
            )
          end
        end

        context 'with filter' do
          let(:work_item_fields) do
            <<~GRAPHQL
              id
              widgets {
                type
                ... on WorkItemWidgetCurrentUserTodos {
                  currentUserTodos(state: done) {
                    nodes {
                      id
                      state
                    }
                  }
                }
              }
            GRAPHQL
          end

          it 'returns widget information' do
            expect(work_item_data).to include(
              'id' => work_item.to_gid.to_s,
              'widgets' => include(
                hash_including(
                  'type' => 'CURRENT_USER_TODOS',
                  'currentUserTodos' => {
                    'nodes' => match_array(
                      [done_todo].map { |t| { 'id' => t.to_gid.to_s, 'state' => t.state } }
                    )
                  }
                )
              )
            )
          end
        end
      end

      describe 'award emoji widget' do
        let_it_be(:emoji) { create(:award_emoji, name: 'star', awardable: work_item) }
        let_it_be(:upvote) { create(:award_emoji, :upvote, awardable: work_item) }
        let_it_be(:downvote) { create(:award_emoji, :downvote, awardable: work_item) }

        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetAwardEmoji {
                upvotes
                downvotes
                awardEmoji {
                  nodes {
                    name
                  }
                }
              }
            }
          GRAPHQL
        end

        it 'returns widget information' do
          expect(work_item_data).to include(
            'id' => work_item.to_gid.to_s,
            'widgets' => include(
              hash_including(
                'type' => 'AWARD_EMOJI',
                'upvotes' => work_item.upvotes,
                'downvotes' => work_item.downvotes,
                'awardEmoji' => {
                  'nodes' => match_array(
                    [emoji, upvote, downvote].map { |e| { 'name' => e.name } }
                  )
                }
              )
            )
          )
        end
      end

      describe 'linked items widget' do
        let_it_be(:related_item) { create(:work_item, project: project) }
        let_it_be(:blocked_item) { create(:work_item, project: project) }
        let_it_be(:link1) { create(:work_item_link, source: work_item, target: related_item, link_type: 'relates_to') }
        let_it_be(:link2) { create(:work_item_link, source: work_item, target: blocked_item, link_type: 'blocks') }
        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetLinkedItems {
                linkedItems {
                  nodes {
                    linkId
                    linkType
                    linkCreatedAt
                    linkUpdatedAt
                    workItem {
                      id
                    }
                  }
                }
              }
            }
          GRAPHQL
        end

        it 'returns widget information' do
          expect(work_item_data).to include(
            'widgets' => include(
              hash_including(
                'type' => 'LINKED_ITEMS',
                'linkedItems' => { 'nodes' => match_array(
                  [
                    hash_including(
                      'linkId' => link1.to_gid.to_s, 'linkType' => 'relates_to',
                      'linkCreatedAt' => link1.created_at.iso8601, 'linkUpdatedAt' => link1.updated_at.iso8601,
                      'workItem' => { 'id' => related_item.to_gid.to_s }
                    ),
                    hash_including(
                      'linkId' => link2.to_gid.to_s, 'linkType' => 'blocks',
                      'linkCreatedAt' => link2.created_at.iso8601, 'linkUpdatedAt' => link2.updated_at.iso8601,
                      'workItem' => { 'id' => blocked_item.to_gid.to_s }
                    )
                  ]
                ) }
              )
            )
          )
        end

        context 'when inaccessible links are present' do
          let_it_be(:no_access_item) { create(:work_item, title: "PRIVATE", project: create(:project, :private)) }

          before do
            create(:work_item_link, source: work_item, target: no_access_item, link_type: 'relates_to')
          end

          it 'returns only items that the user has access to' do
            expect(graphql_dig_at(work_item_data, :widgets, "linkedItems", "nodes", "linkId"))
              .to match_array([link1.to_gid.to_s, link2.to_gid.to_s])
          end
        end

        context 'when limiting the number of results' do
          it_behaves_like 'sorted paginated query' do
            include_context 'no sort argument'

            let(:first_param) { 1 }
            let(:all_records) { [link1, link2] }
            let(:data_path) { %w[workItem widgets linkedItems] }

            def widget_fields(args)
              query_graphql_field(
                :widgets, {}, query_graphql_field(
                  '... on WorkItemWidgetLinkedItems', {}, query_graphql_field(
                    'linkedItems', args, "#{page_info} nodes { linkId }"
                  )
                )
              )
            end

            def pagination_query(params)
              graphql_query_for('workItem', { 'id' => global_id }, widget_fields(params))
            end

            def pagination_results_data(nodes)
              nodes.map { |item| GlobalID::Locator.locate(item['linkId']) }
            end
          end
        end

        context 'when filtering by link type' do
          let(:work_item_fields) do
            <<~GRAPHQL
              widgets {
                type
                ... on WorkItemWidgetLinkedItems {
                  linkedItems(filter: RELATED) {
                    nodes {
                      linkType
                    }
                  }
                }
              }
            GRAPHQL
          end

          it 'returns items with specified type' do
            widget_data = work_item_data["widgets"].find { |widget| widget.key?("linkedItems") }["linkedItems"]

            expect(widget_data["nodes"].size).to eq(1)
            expect(widget_data.dig("nodes", 0, "linkType")).to eq('relates_to')
          end
        end
      end
    end

    describe 'notes widget' do
      context 'when fetching award emoji from notes' do
        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetNotes {
                discussions(filter: ONLY_COMMENTS, first: 10) {
                  nodes {
                    id
                    notes {
                      nodes {
                        id
                        body
                        maxAccessLevelOfAuthor
                        authorIsContributor
                        awardEmoji {
                          nodes {
                            name
                            user {
                              name
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          GRAPHQL
        end

        let_it_be(:note) { create(:note, project: work_item.project, noteable: work_item, author: developer) }

        before_all do
          create(:award_emoji, awardable: note, name: 'rocket', user: developer)
        end

        it 'returns award emoji data' do
          all_widgets = graphql_dig_at(work_item_data, :widgets)
          notes_widget = all_widgets.find { |x| x['type'] == 'NOTES' }
          notes = graphql_dig_at(notes_widget['discussions'], :nodes).flat_map { |d| d['notes']['nodes'] }

          note_with_emoji = notes.find { |n| n['id'] == note.to_gid.to_s }

          expect(note_with_emoji).to include(
            'awardEmoji' => {
              'nodes' => include(
                hash_including(
                  'name' => 'rocket',
                  'user' => {
                    'name' => developer.name
                  }
                )
              )
            }
          )
        end

        it 'returns author contributor status and max access level' do
          all_widgets = graphql_dig_at(work_item_data, :widgets)
          notes_widget = all_widgets.find { |x| x['type'] == 'NOTES' }
          notes = graphql_dig_at(notes_widget['discussions'], :nodes).flat_map { |d| d['notes']['nodes'] }

          expect(notes).to contain_exactly(
            hash_including('maxAccessLevelOfAuthor' => 'Developer', 'authorIsContributor' => false)
          )
        end

        it 'avoids N+1 queries' do
          another_user = create(:user, developer_of: note.resource_parent)
          create(:note, project: note.project, noteable: work_item, author: another_user)

          post_graphql(query, current_user: developer)

          control = ActiveRecord::QueryRecorder.new { post_graphql(query, current_user: developer) }

          expect_graphql_errors_to_be_empty

          another_note = create(:note, project: work_item.project, noteable: work_item)
          create(:award_emoji, awardable: another_note, name: 'star', user: guest)
          another_user = create(:user, developer_of: note.resource_parent)
          note_with_different_user = create(:note, project: note.project, noteable: work_item, author: another_user)
          create(:award_emoji, awardable: note_with_different_user, name: 'star', user: developer)

          # TODO: Fix existing N+1 queries in https://gitlab.com/gitlab-org/gitlab/-/issues/414747
          expect { post_graphql(query, current_user: developer) }.not_to exceed_query_limit(control).with_threshold(4)
          expect_graphql_errors_to_be_empty
        end

        context 'when work item is associated with a group' do
          let_it_be(:group_work_item) { create(:work_item, :group_level, namespace: group) }
          let_it_be(:group_work_item_note) { create(:note, noteable: group_work_item, author: developer, project: nil) }
          let(:global_id) { group_work_item.to_gid.to_s }

          before_all do
            create(:award_emoji, awardable: group_work_item_note, name: 'rocket', user: developer)
          end

          it 'returns notes for the group work item' do
            all_widgets = graphql_dig_at(work_item_data, :widgets)
            notes_widget = all_widgets.find { |x| x['type'] == 'NOTES' }
            notes = graphql_dig_at(notes_widget['discussions'], :nodes).flat_map { |d| d['notes']['nodes'] }

            expect(notes).to contain_exactly(
              hash_including('body' => group_work_item_note.note)
            )
          end
        end
      end
    end

    describe 'designs widget' do
      include DesignManagementTestHelpers

      let(:work_item_fields) do
        query_graphql_field(
          :widgets, {}, query_graphql_field(
            'type ... on WorkItemWidgetDesigns', {}, query_graphql_field(
              :design_collection, nil, design_collection_fields
            )
          )
        )
      end

      let(:design_collection_fields) { nil }

      let(:post_query) { post_graphql(query, current_user: current_user) }

      let(:design_collection_data) { work_item_data['widgets'].find { |w| w['type'] == 'DESIGNS' }['designCollection'] }

      before do
        project.add_developer(developer)
        enable_design_management
      end

      def id_hash(object)
        a_graphql_entity_for(object)
      end

      shared_examples 'fetch a design-like object by ID' do
        let(:design) { design_a }

        let(:design_fields) do
          [
            :filename,
            query_graphql_field(:project, :id)
          ]
        end

        let(:design_collection_fields) do
          query_graphql_field(object_field_name, object_params, object_fields)
        end

        let(:object_fields) { design_fields }

        context 'when the ID is passed' do
          let(:object_params) { { id: global_id_of(object) } }
          let(:result_fields) { {} }

          let(:expected_fields) do
            result_fields.merge({ 'filename' => design.filename, 'project' => id_hash(project) })
          end

          it 'retrieves the object' do
            post_query
            data = design_collection_data[GraphqlHelpers.fieldnamerize(object_field_name)]

            expect(data).to match(a_hash_including(expected_fields))
          end

          context 'when the user is unauthorized' do
            let(:current_user) { create(:user) }

            it_behaves_like 'a failure to find anything'
          end

          context 'without parameters' do
            let(:object_params) { nil }

            it 'raises an error' do
              post_query

              expect(graphql_errors).to include(no_argument_error)
            end
          end
        end

        context 'when attempting to retrieve an object from a different issue' do
          let(:object_params) { { id: global_id_of(object_on_other_issue) } }

          it_behaves_like 'a failure to find anything'
        end
      end

      context 'when work item is an issue' do
        let_it_be(:issue_work_item) { create(:work_item, :issue, project: project) }
        let_it_be(:issue_work_item1) { create(:work_item, :issue, project: project) }
        let_it_be(:design_a) { create(:design, issue: issue_work_item) }
        let_it_be(:version_a) { create(:design_version, issue: issue_work_item, created_designs: [design_a]) }
        let_it_be(:global_id) { issue_work_item.to_gid.to_s }

        describe '.designs' do
          let(:design_collection_fields) do
            query_graphql_field('designs', {}, "nodes { id event filename }")
          end

          it 'returns design data' do
            post_query

            expect(design_collection_data).to include(
              'designs' => include(
                'nodes' => include(
                  hash_including(
                    'id' => design_a.to_gid.to_s,
                    'event' => 'CREATION',
                    'filename' => design_a.filename
                  )
                )
              )
            )
          end
        end

        describe 'copy_state' do
          let(:design_collection_fields) do
            'copyState'
          end

          it 'returns copyState of designCollection' do
            post_query

            expect(design_collection_data).to include(
              'copyState' => 'READY'
            )
          end
        end

        describe '.versions' do
          let(:design_collection_fields) do
            query_graphql_field('versions', {}, "nodes { id sha createdAt }")
          end

          it 'returns versions data' do
            post_query

            expect(design_collection_data).to include(
              'versions' => include(
                'nodes' => include(
                  hash_including(
                    'id' => version_a.to_gid.to_s,
                    'sha' => version_a.sha,
                    'createdAt' => version_a.created_at.iso8601
                  )
                )
              )
            )
          end
        end

        describe '.version' do
          let(:version) { version_a }

          let(:design_collection_fields) do
            query_graphql_field(:version, version_params, 'id sha')
          end

          context 'with no parameters' do
            let(:version_params) { nil }

            it 'raises an error' do
              post_query

              expect(graphql_errors).to include(a_hash_including("message" => "one of id or sha is required"))
            end
          end

          shared_examples 'a successful query for a version' do
            it 'finds the version' do
              post_query

              data = design_collection_data['version']

              expect(data).to match a_graphql_entity_for(version, :sha)
            end
          end

          context 'with (sha: STRING_TYPE)' do
            let(:version_params) { { sha: version.sha } }

            it_behaves_like 'a successful query for a version'
          end

          context 'with (id: ID_TYPE)' do
            let(:version_params) { { id: global_id_of(version) } }

            it_behaves_like 'a successful query for a version'
          end
        end

        describe '.design' do
          it_behaves_like 'fetch a design-like object by ID' do
            let(:object) { design }
            let(:object_field_name) { :design }

            let(:no_argument_error) do
              a_hash_including("message" => "one of id or filename must be passed")
            end

            let_it_be(:object_on_other_issue) { create(:design, issue: issue_work_item1) }
          end
        end

        describe '.designAtVersion' do
          it_behaves_like 'fetch a design-like object by ID' do
            let(:object) { build(:design_at_version, design: design, version: version) }
            let(:object_field_name) { :design_at_version }

            let(:version) { version_a }

            let(:result_fields) { { 'version' => id_hash(version) } }
            let(:object_fields) do
              design_fields + [query_graphql_field(:version, :id)]
            end

            let(:no_argument_error) do
              a_hash_including("message" => "Field 'designAtVersion' is missing required arguments: id")
            end

            let(:object_on_other_issue) { build(:design_at_version, issue: issue_work_item1) }
          end
        end

        describe 'N+1 query check' do
          let(:design_collection_fields) do
            query_graphql_field('designs', {}, "nodes { id event filename}")
          end

          it 'avoids N+1 queries', :use_sql_query_cache do
            post_query # warmup
            control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) do
              post_query
            end

            create_list(:work_item, 3, namespace: group) do |item|
              create(:design, :with_file, issue: item)
            end

            expect do
              post_query
            end.to issue_same_number_of_queries_as(control_count)
            expect_graphql_errors_to_be_empty
          end
        end
      end

      context 'when work item base type is non issue' do
        let_it_be(:epic) { create(:work_item, :task, namespace: group) }
        let_it_be(:global_id) { epic.to_gid.to_s }

        it 'returns without design' do
          post_query

          expect(epic&.work_item_type&.base_type).not_to match('issue')
          expect(work_item_data['widgets']).not_to include(
            hash_including(
              'type' => 'DESIGNS'
            )
          )
        end
      end
    end

    describe 'development widget' do
      context 'when fetching related feature flags' do
        let_it_be(:merge_request1) { create(:merge_request, source_project: project) }
        let_it_be(:merge_request2) { create(:merge_request, source_project: project, target_branch: 'feature2') }
        let_it_be(:private_project) { create(:project, :repository, :private) }
        let_it_be(:private_merge_request) { create(:merge_request, source_project: private_project) }
        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetDevelopment {
                relatedMergeRequests {
                  nodes {
                    closesWorkItem
                    mergeRequest { id }
                  }
                }
              }
            }
          GRAPHQL
        end

        before_all do
          [merge_request1, merge_request2].each do |merge_request|
            create(
              :merge_requests_closing_issues,
              merge_request: merge_request,
              issue: work_item,
              closes_work_item: false
            )
          end
        end

        before do
          post_graphql(query, current_user: current_user)
        end

        context 'when user is developer' do
          let(:current_user) { developer }

          it 'returns related merge requests in the response' do
            expect(work_item_data).to include(
              'id' => work_item.to_global_id.to_s,
              'widgets' => array_including(
                hash_including(
                  'type' => 'DEVELOPMENT',
                  'relatedMergeRequests' => {
                    'nodes' => containing_exactly(
                      {
                        'mergeRequest' => { 'id' => merge_request1.to_global_id.to_s },
                        'closesWorkItem' => false
                      },
                      {
                        'mergeRequest' => { 'id' => merge_request2.to_global_id.to_s },
                        'closesWorkItem' => false
                      }
                    )
                  }
                )
              )
            )
          end

          it 'avoids N + 1 queries', :use_sql_query_cache do
            # warm-up already done in the before block
            control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
              post_graphql(query, current_user: current_user)
            end
            expect(graphql_errors).to be_blank

            merge_request3 = create(:merge_request, source_project: project, target_branch: 'feature3')
            [merge_request1, merge_request2, merge_request3].each do |merge_request|
              create(
                :merge_requests_closing_issues,
                merge_request: merge_request,
                issue: work_item,
                closes_work_item: true
              )
            end

            expect do
              post_graphql(query, current_user: current_user)
            end.to issue_same_number_of_queries_as(control)
            expect(graphql_errors).to be_blank
          end
        end
      end
    end

    context 'when an Issue Global ID is provided' do
      let(:global_id) { Issue.find(work_item.id).to_gid.to_s }

      it 'allows an Issue GID as input' do
        expect(work_item_data).to include('id' => work_item.to_gid.to_s)
      end
    end
  end

  context 'when the user can not read the work item' do
    let(:current_user) { create(:user) }

    before do
      post_graphql(query)
    end

    it 'returns an access error' do
      expect(work_item_data).to be_nil
      expect(graphql_errors).to contain_exactly(
        hash_including('message' => ::Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR)
      )
    end
  end

  context 'when the user cannot set work item metadata' do
    let(:current_user) { guest }

    before do
      post_graphql(query, current_user: current_user)
    end

    it 'returns correct user permission' do
      expect(work_item_data).to include(
        'id' => work_item.to_gid.to_s,
        'userPermissions' =>
          hash_including(
            'setWorkItemMetadata' => false
          )
      )
    end
  end
end
