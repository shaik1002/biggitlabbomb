<script>
import { GlBanner, GlSprintf, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { parseSeconds, stringifyTime } from '~/lib/utils/datetime_utility';
import { s__ } from '~/locale';

import eventHub, {
  EVENT_OPEN_SESSION_LOGOUT_MODAL,
  EVENT_OPEN_SESSION_WARNING_BANNER,
} from '../session_warning_event_hub';

export default {
  components: {
    GlBanner,
    GlSprintf,
    GlLink,
  },
  props: {
    sessionDurationRemaining: {
      type: Number,
      required: true,
      default: null,
    },
    signInPath: {
      type: String,
      required: true,
      default: null,
    },
  },
  data() {
    return {
      sessionTimeRemaining: this.sessionDurationRemaining,
    };
  },
  computed: {
    buttonAttributes() {
      return {
        target: '_blank',
      };
    },
  },
  mounted() {
    eventHub.$on(EVENT_OPEN_SESSION_WARNING_BANNER, this.onOpenEvent);
  },
  destroyed() {
    eventHub.$off(EVENT_OPEN_SESSION_WARNING_BANNER, this.onOpenEvent);
  },
  methods: {
    onOpenEvent() {
      this.showBanner = true;
      document.addEventListener('visibilitychange', this.onDocumentVisible);
      this.intervalId = setInterval(() => {
        this.sessionTimeRemaining -= 1;
        if (this.sessionTimeRemaining === 1) {
          this.emit$(EVENT_OPEN_SESSION_LOGOUT_MODAL);
          this.closeBanner();
        }
      }, 1000);
    },
    closeBanner() {
      this.showBanner = false;
    },
    onCloseEvent() {
      if (this.intervalId) {
        clearInterval(this.intervalId);
        document.removeEventListener('visibilitychange', this.onDocumentVisible);
        this.intervalId = null;
      }
    },
    onDocumentVisible() {
      if (document.visibilityState === 'visible') {
        this.showBanner = true;
      }
    },
    parsedTimeRemaining() {
      return parseSeconds(this.sessionTimeRemaining);
    },
    humanReadableTimeRemaining() {
      return stringifyTime(this.parsedTimeRemaining());
    },
    bodyText() {
      return s__(`SessionExpire|Your session expires in %{humanReadableTimeRemaining} because your administrator
has enabled %{linkStart}expire session from creation%{linkEnd}. Please sign in again.`);
    },
  },
  cancelProps: {
    attributes: { disabled: true },
  },
  expireSessionDocLink: helpPagePath('administration/settings/account_and_limit_settings', {
    anchor: 'set-sessions-to-expire-from-date-of-creation',
  }),
  i18n: {
    title: s__('SessionExpire|Your session expires soon'),
  },
};
</script>
<template>
  <gl-banner
    v-model="showBanner"
    :title="$options.i18n.title"
    :button-attributes="buttonAttributes"
    button-text="Sign in"
    :button-link="signInPath"
    svg-path="null"
    variant="promotion"
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
  </gl-banner>
</template>
