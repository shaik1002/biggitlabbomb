<script>
import { GlModal, GlFormGroup, GlFormSelect, GlAlert, GlButton } from '@gitlab/ui';
import { differenceBy } from 'lodash';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { __, s__ } from '~/locale';

import {
  WIDGET_TYPE_HIERARCHY,
  WORK_ITEMS_TYPE_MAP,
  WORK_ITEM_ALLOWED_CHANGE_TYPE_MAP,
  WORK_ITEM_TYPE_ENUM_OBJECTIVE,
  WORK_ITEM_TYPE_ENUM_KEY_RESULT,
  sprintfWorkItem,
  I18N_WORK_ITEM_CHANGE_TYPE_PARENT_ERROR,
  I18N_WORK_ITEM_CHANGE_TYPE_CHILD_ERROR,
  I18N_WORK_ITEM_CHANGE_TYPE_MISSING_FIELDS_ERROR,
  WORK_ITEM_WIDGETS_NAME_MAP,
} from '../constants';

import namespaceWorkItemTypesQuery from '../graphql/namespace_work_item_types.query.graphql';
import convertWorkItemMutation from '../graphql/work_item_convert.mutation.graphql';

export default {
  i18n: {
    type: __('Type'),
    subText: s__('WorkItem|Select which type you would like to change this item to.'),
    changeType: s__('WorkItem|Change type'),
  },
  components: {
    GlModal,
    GlFormGroup,
    GlFormSelect,
    GlAlert,
    GlButton,
  },
  mixins: [glFeatureFlagMixin()],
  inject: ['hasOkrsFeature'],
  props: {
    workItemId: {
      type: String,
      required: false,
      default: null,
    },
    workItemType: {
      type: String,
      required: false,
      default: null,
    },
    workItemFullPath: {
      type: String,
      required: false,
      default: null,
    },
    hasChildren: {
      type: Boolean,
      required: false,
      default: false,
    },
    hasParent: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItem: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      selectedWorkItemType: null,
      selectedWorkItemTypeValue: null,
      workItemTypes: [],
      errorMessage: '',
      changeTypeDisabled: true,
      workItemTypeName: '',
      showDifferenceMessage: false,
    };
  },
  apollo: {
    workItemTypes: {
      query: namespaceWorkItemTypesQuery,
      variables() {
        return {
          fullPath: this.workItemFullPath,
        };
      },
      update(data) {
        return data.workspace?.workItemTypes?.nodes;
      },
      skip() {
        return !this.workItemFullPath;
      },
    },
  },
  computed: {
    allowedConversionWorkItemTypes() {
      const workItemTypes = [
        { text: __('Select type'), value: null },
        ...this.getWorkItemTypesDropdownOptions().filter((item) => {
          if (item.text === this.workItemType) {
            return false;
          }
          // Keeping this separate for readability
          if (
            item.value === WORK_ITEM_TYPE_ENUM_OBJECTIVE ||
            item.value === WORK_ITEM_TYPE_ENUM_KEY_RESULT
          ) {
            return this.isOkrsEnabled;
          }
          return WORK_ITEM_ALLOWED_CHANGE_TYPE_MAP.includes(item.value);
        }),
      ];

      return workItemTypes;
    },
    isOkrsEnabled() {
      return this.hasOkrsFeature && this.glFeatures.okrsMvc;
    },
    newWorkItemTypeWidgetDefinitions() {
      return this.getWidgetDefinitions(this.selectedWorkItemType?.text);
    },
    currentWorkItemTypeWidgetDefinitions() {
      return this.getWidgetDefinitions(this.workItemType);
    },
    widgetDifference() {
      const widgetDiff = differenceBy(
        this.currentWorkItemTypeWidgetDefinitions,
        this.newWorkItemTypeWidgetDefinitions,
        'type',
      );
      return widgetDiff;
    },
    widgetsData() {
      const affectedData = this.widgetDifference.filter((item) => {
        const widgetObject = this.workItem.widgets?.find((widget) => widget.type === item.type);
        const fieldName = Object.keys(widgetObject).find(
          (key) => key !== 'type' && key !== '__typename',
        );
        // Find the dynamic field to check
        return widgetObject[fieldName]?.nodes !== undefined
          ? widgetObject[fieldName]?.nodes?.length > 0
          : Boolean(widgetObject[fieldName]);
      });
      return affectedData.map((item) => ({
        ...item,
        name: WORK_ITEM_WIDGETS_NAME_MAP[item.type],
      }));
    },
    hasWidgetDifference() {
      return this.widgetsData.length > 0;
    },
    parentWorkItem() {
      return this.workItem.widgets?.find((widget) => widget.type === WIDGET_TYPE_HIERARCHY)?.parent;
    },
    parentWorkItemType() {
      return this.parentWorkItem?.workItemType?.name;
    },
  },
  methods: {
    getWorkItemTypeId() {
      return this.workItemTypes.find((type) => type.name === this.selectedWorkItemType.text).id;
    },
    // This function will be removed once we implement
    // https://gitlab.com/gitlab-org/gitlab/-/issues/498656
    getWorkItemTypesDropdownOptions() {
      return Object.entries(WORK_ITEMS_TYPE_MAP).map(([key, value]) => {
        return {
          text: value.value,
          value: key,
        };
      });
    },
    async changeType() {
      try {
        const {
          data: {
            workItemConvert: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: convertWorkItemMutation,
          variables: {
            input: {
              id: this.workItemId,
              workItemTypeId: this.getWorkItemTypeId(),
            },
          },
        });
        if (errors.length > 0) {
          this.showAlert(errors[0]);
          return;
        }
        this.$toast.show(s__('WorkItem|Type changed.'));
        this.$emit('workItemTypeChanged');
        this.hide();
      } catch (error) {
        this.showAlert(error);
        Sentry.captureException(error);
      }
    },
    getWidgetDefinitions(type) {
      if (!type) {
        return [];
      }
      return this.workItemTypes.find((widget) => widget.name === type).widgetDefinitions;
    },
    validateWorkItemType(value) {
      this.errorMessage = '';
      if (!value) {
        return;
      }
      this.changeTypeDisabled = false;
      this.selectedWorkItemType = this.allowedConversionWorkItemTypes.find(
        (item) => item.value === value,
      );
      this.selectedWorkItemTypeValue = this.selectedWorkItemType.value;

      // Check if there is a parent
      if (this.hasParent) {
        this.showAlert(
          sprintfWorkItem(
            I18N_WORK_ITEM_CHANGE_TYPE_PARENT_ERROR,
            this.selectedWorkItemType.text,
            this.parentWorkItemType,
          ),
        );
        return;
      }
      // Check if there are child items
      if (this.hasChildren) {
        this.showAlert(
          sprintfWorkItem(I18N_WORK_ITEM_CHANGE_TYPE_CHILD_ERROR, this.selectedWorkItemType.text),
        );
        return;
      }

      // Compare the widget definitions of both types
      if (this.hasWidgetDifference) {
        this.showDifferenceMessage = true;
        this.errorMessage = sprintfWorkItem(
          I18N_WORK_ITEM_CHANGE_TYPE_MISSING_FIELDS_ERROR,
          this.selectedWorkItemType.text,
        );
      }
    },
    showAlert(error) {
      this.errorMessage = error;
      this.changeTypeDisabled = true;
    },
    show() {
      this.$refs.modal.show();
    },
    hide() {
      this.errorMessage = '';
      this.selectedWorkItemType = null;
      this.selectedWorkItemTypeValue = null;
      this.changeTypeDisabled = false;
      this.$refs.modal.hide();
    },
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    modal-id="work-item-change-type"
    :title="$options.i18n.changeType"
    category="primary"
    size="sm"
  >
    <div class="gl-flex gl-flex-col">
      <span class="gl-mb-4"> {{ $options.i18n.subText }} </span>
      <gl-form-group data-testid="type" :label="$options.i18n.type" label-for="types">
        <gl-form-select
          id="types"
          v-model="selectedWorkItemTypeValue"
          data-testid="type-select"
          width="md"
          :options="allowedConversionWorkItemTypes"
          @change="validateWorkItemType"
        />
      </gl-form-group>
      <gl-alert
        v-if="errorMessage"
        variant="warning"
        :dismissible="false"
        @dismiss="errorMessage = null"
      >
        <span>{{ errorMessage }}</span>
        <ul v-if="showDifferenceMessage" class="gl-mb-0">
          <li v-for="widget in widgetsData" :key="widget.type">
            {{ widget.name }}
          </li>
        </ul>
      </gl-alert>
    </div>
    <template #modal-footer>
      <div class="gl-m-0 gl-flex gl-flex-row gl-flex-wrap gl-justify-end">
        <gl-button data-testid="change-type-cancel-button" @click="hide">
          {{ __('Cancel') }}
        </gl-button>
        <div class="gl-mr-3"></div>
        <gl-button
          :disabled="changeTypeDisabled"
          category="primary"
          variant="confirm"
          data-testid="change-type-confirmation-button"
          @click="changeType"
          >{{ $options.i18n.changeType }}</gl-button
        >
      </div>
    </template>
  </gl-modal>
</template>
