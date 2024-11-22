<script>
import {
  GlLoadingIcon,
  GlIcon,
  GlButton,
  GlTooltipDirective,
  GlSprintf,
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
} from '@gitlab/ui';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

import { s__, __ } from '~/locale';
import { findWidget } from '~/issues/list/utils';

import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import { sprintfWorkItem, WIDGET_TYPE_DEVELOPMENT, STATE_OPEN } from '~/work_items/constants';

import WorkItemDevelopmentRelationshipList from './work_item_development_relationship_list.vue';
import WorkItemCreateBranchMergeRequestModal from './work_item_create_branch_merge_request_modal.vue';

export default {
  components: {
    GlLoadingIcon,
    GlIcon,
    GlButton,
    GlSprintf,
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    WorkItemDevelopmentRelationshipList,
    WorkItemCreateBranchMergeRequestModal,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    workItemIid: {
      type: String,
      required: true,
    },
    workItemFullPath: {
      type: String,
      required: true,
    },
    workItemId: {
      type: String,
      required: true,
    },
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    workItem: {
      query: workItemByIidQuery,
      variables() {
        return {
          fullPath: this.workItemFullPath,
          iid: this.workItemIid,
        };
      },
      update(data) {
        return data.workspace?.workItem || {};
      },
      skip() {
        return !this.workItemIid;
      },
      error(e) {
        this.$emit('error', this.$options.i18n.fetchError);
        this.error = e.message || this.$options.i18n.fetchError;
      },
    },
  },
  data() {
    return {
      error: '',
      showCreateBranchAndMrModal: false,
      branchFlow: true,
      mergeRequestFlow: false,
      isDropdownShown: false,
    };
  },
  computed: {
    canUpdate() {
      return this.workItem?.userPermissions?.updateWorkItem;
    },
    workItemState() {
      return this.workItem?.state;
    },
    workItemTypeName() {
      return this.workItem?.workItemType?.name;
    },
    workItemDevelopment() {
      return findWidget(WIDGET_TYPE_DEVELOPMENT, this.workItem);
    },
    isLoading() {
      return this.$apollo.queries.workItem.loading;
    },
    willAutoCloseByMergeRequest() {
      return this.workItemDevelopment?.willAutoCloseByMergeRequest;
    },
    linkedMergeRequests() {
      return this.workItemDevelopment?.closingMergeRequests?.nodes || [];
    },
    featureFlags() {
      return this.workItemDevelopment?.featureFlags?.nodes || [];
    },
    shouldShowEmptyState() {
      return this.isRelatedDevelopmentListEmpty ? this.workItemsAlphaEnabled : true;
    },
    shouldShowDevWidget() {
      return this.workItemDevelopment && this.shouldShowEmptyState;
    },
    isRelatedDevelopmentListEmpty() {
      return !this.error && this.linkedMergeRequests.length === 0 && this.featureFlags.length === 0;
    },
    showAutoCloseInformation() {
      return (
        this.linkedMergeRequests.length > 0 && this.willAutoCloseByMergeRequest && !this.isLoading
      );
    },
    openStateText() {
      return this.linkedMergeRequests.length > 1
        ? sprintfWorkItem(this.$options.i18n.openStateText, this.workItemTypeName)
        : sprintfWorkItem(
            this.$options.i18n.openStateWithOneMergeRequestText,
            this.workItemTypeName,
          );
    },
    closedStateText() {
      return sprintfWorkItem(this.$options.i18n.closedStateText, this.workItemTypeName);
    },
    tooltipText() {
      return this.workItemState === STATE_OPEN ? this.openStateText : this.closedStateText;
    },
    workItemsAlphaEnabled() {
      return this.glFeatures.workItemsAlpha;
    },
    showAddButton() {
      return this.workItemsAlphaEnabled && this.canUpdate;
    },
    mergeRequestGroup() {
      const items = [];

      items.push({
        text: this.$options.i18n.createMergeRequest,
        action: this.openModal.bind(this, false, true),
        extraAttrs: {
          'data-testid': 'create-mr-dropdown-button',
        },
      });

      return { items, name: __('Merge request') };
    },
    branchGroup() {
      const items = [];

      items.push({
        text: this.$options.i18n.createBranch,
        action: this.openModal.bind(this, true, false),
        extraAttrs: {
          'data-testid': 'create-branch-dropdown-button',
        },
      });

      return { items, name: __('Branch') };
    },
    addButtonTitle() {
      return this.isDropdownShown ? '' : __('Add branch or merge request');
    },
  },
  methods: {
    openModal(createBranch = true, createMergeRequest = false) {
      this.toggleCreateModal(true);
      this.branchFlow = createBranch;
      this.mergeRequestFlow = createMergeRequest;
    },
    toggleCreateModal(showOrhide) {
      this.showCreateBranchAndMrModal = showOrhide;
    },
    onHideDropdown() {
      this.isDropdownShown = false;
    },
    onShowDropdown() {
      this.isDropdownShown = true;
    },
  },
  i18n: {
    development: s__('WorkItem|Development'),
    fetchError: s__('WorkItem|Something went wrong when fetching items. Please refresh this page.'),
    createMergeRequest: __('Create merge request'),
    createBranch: __('Create branch'),
    openStateWithOneMergeRequestText: s__(
      'WorkItem|This %{workItemType} will be closed when the following is merged.',
    ),
    openStateText: s__(
      'WorkItem|This %{workItemType} will be closed when any of the following is merged.',
    ),
    closedStateText: s__(
      'WorkItem|The %{workItemType} was closed automatically when a branch was merged.',
    ),
    createMergeRequestOrBranch: __('Create a %{mergeRequest} or a %{branch}.'),
    mergeRequest: __('merge request'),
    branch: __('branch'),
  },
};
</script>
<template>
  <gl-loading-icon v-if="isLoading" class="gl-my-2" />
  <div v-else-if="shouldShowDevWidget" class="work-item-attributes-item">
    <div class="gl-flex gl-items-center gl-justify-between gl-gap-3">
      <h3
        class="gl-heading-5 !gl-mb-0 gl-flex gl-items-center gl-gap-2"
        data-testid="dev-widget-label"
      >
        {{ $options.i18n.development }}
        <gl-button
          v-if="showAutoCloseInformation"
          v-gl-tooltip
          class="!gl-p-0 hover:!gl-bg-transparent"
          category="tertiary"
          :title="tooltipText"
          :aria-label="tooltipText"
          data-testid="more-information"
        >
          <gl-icon name="information-o" variant="info" />
        </gl-button>
      </h3>
      <gl-disclosure-dropdown
        data-testid="create-options-dropdown"
        @hidden="onHideDropdown"
        @shown="onShowDropdown"
      >
        <template #toggle>
          <gl-button
            v-if="showAddButton"
            v-gl-tooltip.top
            category="tertiary"
            icon="plus"
            size="small"
            data-testid="add-item"
            :title="addButtonTitle"
            :aria-label="addButtonTitle"
          />
        </template>

        <gl-disclosure-dropdown-group :group="mergeRequestGroup" />

        <gl-disclosure-dropdown-group bordered :group="branchGroup" />
      </gl-disclosure-dropdown>
    </div>
    <work-item-development-relationship-list
      v-if="!isRelatedDevelopmentListEmpty"
      :work-item-dev-widget="workItemDevelopment"
    />
    <template v-else>
      <span v-if="!canUpdate" class="gl-text-secondary">{{ __('None') }}</span>
      <template v-else>
        <span class="gl-text-sm gl-text-subtle">
          <gl-sprintf :message="$options.i18n.createMergeRequestOrBranch">
            <template #mergeRequest>
              <gl-button
                variant="link"
                class="gl-align-baseline !gl-text-sm"
                data-testid="create-mr-button"
                @click="openModal(false, true)"
              >
                {{ $options.i18n.mergeRequest }}
              </gl-button>
            </template>
            <template #branch>
              <gl-button
                variant="link"
                class="gl-align-baseline !gl-text-sm"
                data-testid="create-branch-button"
                @click="openModal(true, false)"
              >
                {{ $options.i18n.branch }}
              </gl-button>
            </template>
          </gl-sprintf>
        </span>
      </template>
    </template>
    <work-item-create-branch-merge-request-modal
      :show-modal="showCreateBranchAndMrModal"
      :branch-flow="branchFlow"
      :merge-request-flow="mergeRequestFlow"
      :work-item-iid="workItemIid"
      :work-item-id="workItemId"
      :work-item-type="workItemTypeName"
      @hideModal="toggleCreateModal(false)"
    />
  </div>
</template>
