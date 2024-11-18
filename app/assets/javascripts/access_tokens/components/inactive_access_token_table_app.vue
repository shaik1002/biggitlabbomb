<script>
import { GlIcon, GlLink, GlPagination, GlTable, GlTooltipDirective } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import axios from '~/lib/utils/axios_utils';
import {
  convertObjectPropsToCamelCase,
  normalizeHeaders,
  parseIntPagination,
} from '~/lib/utils/common_utils';
import { s__, __ } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UserDate from '~/vue_shared/components/user_date.vue';
import { INACTIVE_TOKENS_TABLE_FIELDS } from './constants';

export default {
  name: 'InactiveAccessTokenTableApp',
  components: {
    GlIcon,
    GlLink,
    GlPagination,
    GlTable,
    TimeAgoTooltip,
    UserDate,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  lastUsedHelpLink: helpPagePath('/user/profile/personal_access_tokens.md', {
    anchor: 'view-the-last-time-a-token-was-used',
  }),
  i18n: {
    emptyField: __('Never'),
    expired: __('Expired'),
    revoked: __('Revoked'),
    lastTimeUsed: s__('AccessTokens|The last time a token was used'),
  },
  inject: ['noInactiveTokensMessage', 'paginationUrl'],
  data() {
    return {
      inactiveAccessTokens: [],
      busy: false,
      emptyText: '',
      page: 1,
      perPage: 0,
      total: 0,
    };
  },
  computed: {
    filteredFields() {
      // Remove the sortability of the columns
      return INACTIVE_TOKENS_TABLE_FIELDS.map((field) => ({
        ...field,
        sortable: false,
      }));
    },
    showPagination() {
      return this.total > this.perPage;
    },
  },
  created() {
    this.fetchData();
  },
  methods: {
    async fetchData(newPage = '1') {
      const url = new URL(this.paginationUrl);
      url.searchParams.append('page', newPage);

      this.busy = true;
      const { data, headers } = await axios.get(url.toString());

      const { page, perPage, total } = parseIntPagination(normalizeHeaders(headers));
      this.page = page;
      this.perPage = perPage;
      this.total = total;
      this.busy = false;
      this.inactiveAccessTokens = convertObjectPropsToCamelCase(data, { deep: true });
      this.emptyText = this.noInactiveTokensMessage;
    },
    async pageChanged(newPage) {
      await this.fetchData(newPage.toString());
    },
  },
};
</script>

<template>
  <div>
    <gl-table
      data-testid="inactive-access-tokens"
      :empty-text="emptyText"
      :fields="filteredFields"
      :items="inactiveAccessTokens"
      show-empty
      stacked="sm"
      class="gl-overflow-x-auto"
      :busy="busy"
    >
      <template #cell(createdAt)="{ item: { createdAt } }">
        <user-date :date="createdAt" />
      </template>

      <template #head(lastUsedAt)="{ label }">
        <span>{{ label }}</span>
        <gl-link :href="$options.lastUsedHelpLink"
          ><gl-icon name="question-o" class="gl-ml-2" /><span class="gl-sr-only">{{
            $options.i18n.lastTimeUsed
          }}</span></gl-link
        >
      </template>

      <template #cell(lastUsedAt)="{ item: { lastUsedAt } }">
        <time-ago-tooltip v-if="lastUsedAt" :time="lastUsedAt" />
        <template v-else> {{ $options.i18n.emptyField }}</template>
      </template>

      <template #cell(expiresAt)="{ item: { expiresAt, revoked } }">
        <span v-if="revoked" v-gl-tooltip :title="$options.i18n.tokenValidity">{{
          $options.i18n.revoked
        }}</span>
        <template v-else>
          <span>{{ $options.i18n.expired }}</span>
          <time-ago-tooltip :time="expiresAt" />
        </template>
      </template>
    </gl-table>
    <gl-pagination
      v-if="showPagination"
      :value="page"
      :per-page="perPage"
      :total-items="total"
      :disabled="busy"
      align="center"
      class="gl-mt-5"
      @input="pageChanged"
    />
  </div>
</template>
