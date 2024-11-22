<script>
import { GlForm, GlFormInput, GlFormGroup, GlModal } from '@gitlab/ui';
import { debounce } from 'lodash';
import axios from '~/lib/utils/axios_utils';
import { createAlert } from '~/alert';
import { mergeUrlParams, visitUrl } from '~/lib/utils/url_utility';
import {
  findInvalidBranchNameCharacters,
  humanizeBranchValidationErrors,
} from '~/lib/utils/text_utility';
import { __, sprintf } from '~/locale';

export default {
  components: {
    GlForm,
    GlFormInput,
    GlFormGroup,
    GlModal,
  },
  i18n: {
    sourceLabel: __('Source (branch or tag)'),
    branchLabel: __('Branch name'),
    createBranch: __('Create branch'),
    cancelLabel: __('Cancel'),
    createMergeRequest: __('Create merge request'),
    branchNameExists: __('Branch is already taken'),
    sourceNotAvailable: __('Source is not available'),
    branchNameAvailable: __('Branch name is available'),
    sourceIsAvailable: __('Source is available'),
    branchNameIsRequired: __('Branch name is required'),
    sourceNameIsRequired: __('Source name is required'),
    checkingSourceValidity: __('Checking source validity'),
    checkingBranchValidity: __('Checking branch validity'),
  },
  inject: [
    'canCreatePath',
    'fullPath',
    'defaultBranch',
    'createBranchPath',
    'createMrPath',
    'refsPath',
  ],
  createMRModalId: 'create-merge-request-modal',
  props: {
    showModal: {
      type: Boolean,
      required: false,
      default: false,
    },
    branchFlow: {
      type: Boolean,
      required: false,
      default: true,
    },
    mergeRequestFlow: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemIid: {
      type: String,
      required: true,
    },
    workItemId: {
      type: String,
      required: true,
    },
    workItemType: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
      canCreateBranch: false,
      branchName: '',
      sourceName: '',
      invalidSource: false,
      invalidBranch: false,
      invalidForm: false,
      sourceDescription: '',
      branchDescription: '',
      checkingSourceValidity: false,
      checkingBranchValidity: false,
      creatingBranch: false,
    };
  },
  computed: {
    createButtonText() {
      return this.branchFlow
        ? this.$options.i18n.createBranch
        : this.$options.i18n.createMergeRequest;
    },
    sourceFeedback() {
      return this.sourceName.length
        ? this.$options.i18n.sourceNotAvailable
        : this.$options.i18n.sourceNameIsRequired;
    },
    branchFeedback() {
      const branchErrors = findInvalidBranchNameCharacters(this.branchName);
      if (!this.branchName.length) {
        return this.$options.i18n.branchNameIsRequired;
      }
      if (branchErrors.length) {
        return humanizeBranchValidationErrors(branchErrors);
      }
      return this.$options.i18n.branchNameExists;
    },
    modalTitle() {
      return this.branchFlow
        ? this.$options.i18n.createBranch
        : this.$options.i18n.createMergeRequest;
    },
    saveButtonAction() {
      return {
        text: this.createButtonText,
        attributes: {
          variant: 'confirm',
          disabled: this.invalidForm,
          loading:
            this.checkingSourceValidity || this.checkingBranchValidity || this.creatingBranch,
        },
      };
    },
    cancelButtonAction() {
      return {
        text: this.$options.i18n.cancelLabel,
      };
    },
  },
  watch: {
    showModal(newVal, oldVal) {
      if (newVal !== oldVal && newVal === true) {
        this.init();
      }
    },
  },
  mounted() {
    this.init();
  },
  methods: {
    async init() {
      if (!this.canCreatePath.match(/\/(\d+)/).length) {
        return;
      }
      const createPathId = this.canCreatePath.match(/\/(\d+)/)[1];
      /** the injected path only injects the path for the parent work item id
       * we need to make sure that the path is right for the children/modal ids
       */
      const createPath = this.canCreatePath.replace(createPathId, this.workItemIid);
      this.isLoading = true;
      const {
        data: { can_create_branch, suggested_branch_name },
      } = await axios.get(createPath);

      this.isLoading = false;
      /** The legacy API is returning values in camelcase format has have to use it here */
      /** Can be changed when we migrate the response to graphql */
      /* eslint-disable camelcase */
      this.canCreateBranch = can_create_branch;

      if (this.canCreateBranch) {
        this.branchName = suggested_branch_name;
        /* eslint-enable camelcase */
        this.sourceName = this.defaultBranch;
      }
    },
    async createBranch() {
      const endpoint = mergeUrlParams(
        { ref: this.defaultBranch, branch_name: this.branchName },
        this.createBranchPath,
      );

      this.creatingBranch = true;

      await axios
        .post(endpoint, {
          confidential_issue_project_id: null,
        })
        .then(({ data }) => {
          this.branchCreated = true;

          this.$toast.show(__('Branch created.'), {
            autoHideDelay: 10000,
            action: {
              text: __('View branch'),
              onClick: () => {
                visitUrl(data.url);
              },
            },
          });

          this.$emit('hideModal');
        })
        .catch(() =>
          createAlert({
            message: sprintf(
              __('Failed to create a branch for this %{workItemType}. Please try again.'),
              { workItemType: this.workItemType.toLowerCase() },
            ),
          }),
        )
        .finally(() => {
          this.creatingBranch = false;
        });
    },
    async createMergeRequest() {
      await this.createBranch();
      let path = this.createMrPath;
      path = mergeUrlParams(
        {
          'merge_request[issue_iid]': this.workItemIid,
          'merge_request[target_branch]': this.defaultBranch,
          'merge_request[source_branch]': this.branchName,
        },
        path,
      );

      /** open the merge request once we have it created */
      visitUrl(path);
    },
    createEntity() {
      if (this.branchFlow) {
        this.createBranch();
      } else {
        this.createMergeRequest();
      }
    },
    fetchRefs(refValue, target) {
      if (!refValue || !refValue.trim().length) {
        this.invalidSource = target === 'source';
        this.invalidBranch = target === 'branch';
        this.invalidForm = true;
        return;
      }

      if (target === 'source') {
        this.checkingSourceValidity = true;
        this.sourceDescription = __('Checking source validity...');
      } else {
        this.checkingBranchValidity = true;
        this.branchDescription = __('Checking branch validity...');
      }

      this.refCancelToken = axios.CancelToken.source();

      axios
        .get(`${this.refsPath}${encodeURIComponent(refValue)}`, {
          cancelToken: this.refCancelToken.token,
        })
        .then(({ data }) => {
          const branches = data[Object.keys(data)[0]];
          const tags = data[Object.keys(data)[1]];

          if (target === 'source') {
            this.invalidSource = !(
              branches.indexOf(refValue) !== -1 || tags.indexOf(refValue) !== -1
            );
          } else {
            this.invalidBranch = Boolean(
              branches.indexOf(refValue) !== -1 || findInvalidBranchNameCharacters(refValue).length,
            );
          }

          this.invalidForm = this.invalidSource || this.invalidBranch;
        })
        .catch((thrown) => {
          if (axios.isCancel(thrown)) {
            return false;
          }
          createAlert({
            message: __('Failed to get ref.'),
          });
          return false;
        })
        .finally(() => {
          this.checkingSourceValidity = false;
          this.checkingBranchValidity = false;
        });
    },
    checkValidity: debounce(function debouncedCheckValidity(refValue, target) {
      return this.fetchRefs(refValue, target);
    }, 250),
  },
};
</script>

<template>
  <div>
    <gl-modal
      ref="create-modal"
      :visible="showModal || creatingBranch"
      :title="modalTitle"
      :modal-id="$options.createMRModalId"
      :action-primary="saveButtonAction"
      :action-cancel="cancelButtonAction"
      size="sm"
      @primary.prevent="createEntity"
      @hide="$emit('hideModal')"
    >
      <gl-form class="gl-text-left">
        <gl-form-group
          id="source-name-group"
          required
          label-for="source-name-id"
          :label="$options.i18n.sourceLabel"
          :description="checkingSourceValidity ? sourceDescription : ''"
          :invalid-feedback="checkingSourceValidity || isLoading ? '' : sourceFeedback"
          :valid-feedback="
            checkingSourceValidity || isLoading ? '' : $options.i18n.sourceIsAvailable
          "
          :state="sourceName ? !invalidSource : false"
        >
          <gl-form-input
            id="source-name-id"
            v-model.trim="sourceName"
            :state="!invalidSource"
            required
            name="source-name"
            type="text"
            :disabled="isLoading || creatingBranch"
            @input="checkValidity($event, 'source')"
          />
        </gl-form-group>
        <gl-form-group
          id="branch-name-group"
          required
          label-for="branch-name-id"
          :label="$options.i18n.branchLabel"
          :description="checkingBranchValidity ? branchDescription : ''"
          :invalid-feedback="checkingBranchValidity || isLoading ? '' : branchFeedback"
          :valid-feedback="
            checkingBranchValidity || isLoading ? '' : $options.i18n.branchNameAvailable
          "
          :state="branchName ? !invalidBranch : false"
        >
          <gl-form-input
            id="branch-name-id"
            v-model.trim="branchName"
            :state="!invalidBranch"
            :disabled="isLoading || creatingBranch"
            required
            name="branch-name"
            type="text"
            @input="checkValidity($event, 'branch')"
          />
        </gl-form-group>
      </gl-form>
    </gl-modal>
  </div>
</template>
