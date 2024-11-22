import { GlLink, GlBanner } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import SessionWarningBanner from '~/sessions/timeout/components/session_warning_banner.vue';
import eventHub, {
  EVENT_OPEN_SESSION_LOGOUT_MODAL,
  EVENT_OPEN_SESSION_WARNING_BANNER,
} from '~/sessions/timeout/session_warning_event_hub';

jest.useFakeTimers();

jest.mock('');

describe('ExpireSessionWarningBanner', () => {
  let wrapper;

  const defaultProps = {
    sessionDurationRemaning: 5 * 60 * 60,
    signInPath: '//signInPath',
  };

  const createComponent = (props = {}) => {
    wrapper = mountExtended(SessionWarningBanner, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findGlBanner = () => wrapper.findComponent(GlBanner);
  const findGlLink = () => findGlBanner().findComponent(GlLink);
  const findLogoutButton = () => wrapper.findByTestId('session-warning-banner-button');
  const emitButtonFromBanner = (button) => () =>
    button().vm.$emit('click', { preventDefault: jest.fn() });

  const clickLogout = emitButtonFromBanner(findLogoutButton);
  const emitBannerEvent = () => {
    eventHub.$emit(EVENT_OPEN_SESSION_WARNING_BANNER, {
      sessionDurationRemaning: 5 * 60 * 60,
      signInPath: '//signInPath',
    });
  };
  beforeEach(() => {
    createComponent();
  });

  describe('when banner event is emitted', () => {
    emitBannerEvent();
    it('dislays the banner with countdown', () => {
      expect(findGlBanner().props('visible')).toBe(true);
      expect(findGlBanner().sessionTimeRemaining).toBeLessThan(5 * 60 * 60);
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
      expect(findGlBanner().props('visible')).toBe(false);
    });
  });

  describe('when user selects sign in option', () => {
    clickLogout();
    it('hides the banner', () => {
      expect(findGlBanner().props('visible')).toBe(false);
    });
  });
});
