import Vue from 'vue';
import SessionWarningModal from './components/session_warning_modal.vue';
import SessionWarningBanner from './components/session_warning_banner.vue';
import SessionLogoutModal from './components/session_logout_modal.vue';

const initSessionWarningBanner = ({ sessionTimeoutWarning, signInPath }) => {
  return new Vue({
    functional: true,
    render: (createElement) =>
      createElement(SessionWarningBanner, {
        sessionDurationRemaining: sessionTimeoutWarning,
        signInPath,
      }),
  });
};

const initSessionLogoutModal = ({ signInPath }) => {
  return new Vue({
    functional: true,
    render: (createElement) =>
      createElement(SessionLogoutModal, {
        signInPath,
      }),
  });
};

export const initSessionLogoutWarningModal = () => {
  const el = document.getElementById('js-expire-session-warning');

  if (!el) return;

  const { sessionTimeout, signInPath } = el.data;
  // Warn 5 minutes in advance
  let sessionTimeoutInterval = sessionTimeout - 5 * 60;
  let sessionTimeoutWarning = sessionTimeoutInterval;
  if (sessionTimeoutInterval < 0) {
    // Session timeout is less than five minutes, warn immediately
    sessionTimeoutInterval = 0;
    sessionTimeoutWarning = sessionTimeout;
  }
  let modal = null;
  setTimeout(() => {
    if (modal) {
      return;
    }
    const child = document.createElement('div');
    el.appendChild(child);
    modal = new Vue({
      child,
      render: (createElement) =>
        createElement(SessionWarningModal, {
          props: {
            sessionDurationRemaining: sessionTimeoutWarning,
            signInPath,
          },
        }),
    });
  }, sessionTimeoutInterval * 1000);
  initSessionWarningBanner(sessionTimeoutWarning, signInPath);
  initSessionLogoutModal(signInPath);
};
