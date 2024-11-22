<script>
import { GlModal, GlSprintf, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __, s__ } from '~/locale';
import { parseSeconds, stringifyTime } from '~/lib/utils/datetime_utility';

import eventHub, {
  EVENT_OPEN_SESSION_LOGOUT_MODAL,
  EVENT_OPEN_SESSION_WARNING_BANNER,
} from '../session_warning_event_hub';

export default {
  components: {
    GlModal,
    GlSprintf,
    GlLink,
  },
  props: {
    sessionDurationRemaining: {
      type: Number,
      required: true,
    },
    signInPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    parsedTimeRemaining() {
      return parseSeconds(this.sessionTimeRemaining);
    },
    humanReadableTimeRemaining() {
      return stringifyTime(this.parsedTimeRemaining());
    },
    bodyText() {
      return s__(`SessionExpire|Your session expires in %{humanReadableTimeRemaining} because your administrator
          has enabled %{linkStart}expire session from creation%{linkEnd}. Save your work and sign in again.`);
    },
  },
  created() {
    this.startCountdown();
    this.showModal = true;
    document.addEventListener('visibilitychange', this.onDocumentVisible);
  },
  methods: {
    startCountdown() {
      this.intervalId = setInterval(() => {
        this.sessionTimeRemaining -= 1;
        if (this.sessionTimeRemaining === 1) {
          this.emit$(EVENT_OPEN_SESSION_LOGOUT_MODAL);
          this.closeModal();
        }
      }, 1000);
    },
    secondaryAction() {
      eventHub.$emit(EVENT_OPEN_SESSION_WARNING_BANNER, {
        sessionTimeRemaining: this.sessionTimeRemaining,
        signInPath: this.signInPath,
      });
      this.closeModal();
    },
    closeModal() {
      this.showModal = false;
      this.cleanEvents();
    },
    onDocumentVisible() {
      if (document.visibilityState === 'visible') {
        this.showModal = true;
      }
    },
    cleanEvents() {
      if (this.intervalId) {
        clearInterval(this.intervalId);
        document.removeEventListener('visibilitychange', this.onDocumentVisible);
        this.intervalId = null;
      }
    },
  },
  primaryProps: {
    text: this.$options.i18n.signIn,
    attributes: {
      href: this.data.signInPath,
    },
  },
  cancelProps: {
    attributes: { text: true },
  },
  secondaryProps: {
    text: __('Continue working'),
  },
  i18n: {
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
    modal-id="session-timeout-warning-modal"
    :title="_s_('SessionExpire|Your session expires soon')"
    :action-primary="primaryProps"
    :action-secondary="secondaryProps"
    :action-cancel="cancelProps"
    @secondary="secondaryAction"
  >
    <gl-sprintf :message="bodyText">
      <template #humanReadableTimeRemaining>
        {{ humanReadableTimeRemaining }}
      </template>
      <template #link="{ content }">
        <gl-link :href="$options.expireSessionDocLink" target="_blank">
          {{ content }}
        </gl-link>
      </template>
    </gl-sprintf>
  </gl-modal>
</template>
