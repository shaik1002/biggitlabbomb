import { GlModal, GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import eventHub, {
  EVENT_OPEN_SESSION_LOGOUT_MODAL,
  EVENT_OPEN_SESSION_WARNING_BANNER,
} from '~/sessions/timeout/session_warning_event_hub';
import SessionWarningModal from '~/sessions/timeout/components/session_warning_modal.vue';

jest.useFakeTimers();

jest.mock('');

describe('ExpireSessionWarningModal', () => {
  let wrapper;

  const defaultProps = {
    sessionDurationRemaning: 5 * 60 * 60, // 5 minutes in seconds
    signInPath: '//signInPath',
  };

  const createComponent = (props = {}) => {
    wrapper = mountExtended(SessionWarningModal, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findGlModal = () => wrapper.findComponent(GlModal);
  const findGlLink = () => findGlModal().findComponent(GlLink);
  const findModalBodyText = () => wrapper.findByTestId('session-warning-modal-body').text();
  const findLogoutButton = () => wrapper.findByTestId('session-warning-modal-primary');
  const findContinueButton = () => wrapper.findByTestId('session-warning-modal-secondary');
  const emitButtonFromModal = (button) => () =>
    button().vm.$emit('click', { preventDefault: jest.fn() });

  const clickLogout = emitButtonFromModal(findLogoutButton);
  const clickContinue = emitButtonFromModal(findContinueButton);

  beforeEach(() => {
    createComponent();
  });

  describe('when session is within five minutes of expiration', () => {
    it('displays active session time remaining', () => {
      expect(setInterval()).toHaveBeenCalledTimes(1);
      expect(findGlModal().props('visible')).toBe(true);
      expect(findModalBodyText()).toContain('5 minutes');
      expect(findGlModal().sessionTimeRemaning).toBeLessThan(5 * 60 * 60);
    });
    it('contains a sign in link', () => {
      expect(findGlLink().attributes('href')).toBe('//signInPath');
    });
  });

  describe('when session time expires', () => {
    it('emits logout modal event', () => {
      const emitted = jest.spyOn(eventHub, '$emit');
      expect(emitted).toHaveBeenCalledWith(EVENT_OPEN_SESSION_LOGOUT_MODAL);
    });
    it('hides the modal', () => {
      expect(findGlModal().props('visible')).toBe(false);
    });
  });

  describe('when user selects sign in option', () => {
    clickLogout();
    it('hides the modal', () => {
      expect(findGlModal().props('visible')).toBe(false);
    });
  });

  describe('when user selects continue working', () => {
    clickContinue();
    it('emits show warning banner event', () => {
      const emitted = jest.spyOn(eventHub, '$emit');
      expect(emitted).toHaveBeenCalledWith(EVENT_OPEN_SESSION_WARNING_BANNER, {
        sessionTimeRemaining: defaultProps.sessionDurationRemaning,
        signInPath: defaultProps.signInPath,
      });
    });

    it('hides the modal', () => {
      expect(findGlModal().props('visible')).toBe(false);
    });
  });
});
