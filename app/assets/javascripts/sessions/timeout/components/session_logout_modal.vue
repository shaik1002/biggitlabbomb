<script>
import { GlModal, GlSprintf, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __, s__ } from '~/locale';

import eventHub, { EVENT_OPEN_SESSION_LOGOUT_MODAL } from '../session_warning_event_hub';

export default {
  components: {
    GlModal,
    GlSprintf,
    GlLink,
  },
  props: {
    signInPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    primaryAction: {
      text: this.$options.i18n.signIn,
      attributes: {
        href: this.signInPath,
      },
    },
  },
  destroyed() {
    eventHub.$off(EVENT_OPEN_SESSION_LOGOUT_MODAL, this.onOpenEvent);
  },
  mounted() {
    eventHub.$on(EVENT_OPEN_SESSION_LOGOUT_MODAL, this.onOpenEvent);
  },
  methods: {
    onOpenEvent() {
      this.openModal();
    },
    openModal() {
      this.showModal = true;
    },
  },
  i18n: {
    bodyText: s__(`SessionExpire|Your session has expired because your administrator
        has enabled %{linkStart}expire session from creation%{linkEnd}. Please sign in again.`),
    signIn: __('Sign in'),
  },
  expireSessionDocLink: helpPagePath('administration/settings/account_and_limit_settings', {
    anchor: 'set-sessions-to-expire-from-date-of-creation',
  }),
};
</script>
<template>
  <gl-modal
    v-model="showModal"
    modal-id="session-logout-modal"
    :title="s__('SessionExpire|Your session has expired')"
    :action-primary="primaryAction"
    visible
    :scrollable="false"
    no-fade=""
  >
    <gl-sprintf :message="options.i18n.bodyText">
      <template #link="{ content }">
        <gl-link :href="$options.expireSessionDocLink" target="_blank">
          {{ content }}
        </gl-link>
      </template>
    </gl-sprintf>
  </gl-modal>
</template>
