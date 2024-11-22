import { GlModal, GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import SessionLogoutModal from '~/sessions/timeout/components/session_logout_modal.vue';
import eventHub, {
  EVENT_OPEN_SESSION_LOGOUT_MODAL,
} from '~/sessions/timeout/session_warning_event_hub';

jest.useFakeTimers();

jest.mock('');

describe('ExpireSessionWarningModal', () => {
  let wrapper;

  const defaultProps = {
    signInPath: '//signInPath',
  };

  const createComponent = (props = {}) => {
    wrapper = mountExtended(SessionLogoutModal, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findGlModal = () => wrapper.findComponent(GlModal);
  const findGlLink = () => findGlModal().findComponent(GlLink);
  const findLogoutButton = () => wrapper.findByTestId('session-logout-modal-primary');
  const emitButtonFromModal = (button) => () =>
    button().vm.$emit('click', { preventDefault: jest.fn() });

  const clickLogout = emitButtonFromModal(findLogoutButton);
  const emitLogoutEvent = () => {
    eventHub.$emit(EVENT_OPEN_SESSION_LOGOUT_MODAL, {
      signInPath: '//signInPath',
    });
  };
  beforeEach(() => {
    createComponent();
  });

  describe('when session time expires', () => {
    emitLogoutEvent();
    it('displays the modal', () => {
      expect(findGlModal().props('visible')).toBe(true);
    });
    it('contains a sign in link', () => {
      expect(findGlLink().attributes('href')).toBe('//signInPath');
    });
  });

  describe('when user selects sign in option', () => {
    clickLogout();
    it('hides the modal', () => {
      expect(findGlModal().props('visible')).toBe(false);
    });
  });
});
