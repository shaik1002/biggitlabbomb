import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RunnerJobStatusBadge from '~/ci/runner/components/runner_job_status_badge.vue';
import {
  I18N_JOB_STATUS_RUNNING,
  I18N_JOB_STATUS_IDLE,
  JOB_STATUS_RUNNING,
  JOB_STATUS_IDLE,
} from '~/ci/runner/constants';

describe('RunnerTypeBadge', () => {
  let wrapper;

  const findBadge = () => wrapper.findComponent(GlBadge);

  const createComponent = ({ props, ...options } = {}) => {
    wrapper = shallowMount(RunnerJobStatusBadge, {
      propsData: {
        ...props,
      },
      ...options,
    });
  };

  it.each`
    jobStatus             | classes                                         | text
    ${JOB_STATUS_RUNNING} | ${['gl-text-blue-600!', 'gl-border-blue-600!']} | ${I18N_JOB_STATUS_RUNNING}
    ${JOB_STATUS_IDLE}    | ${['gl-text-gray-700!', 'gl-border-gray-500!']} | ${I18N_JOB_STATUS_IDLE}
  `(
    'renders $jobStatus job status with "$text" text and styles',
    ({ jobStatus, classes, text }) => {
      createComponent({ props: { jobStatus } });

      expect(findBadge().props()).toMatchObject({ size: 'md', variant: 'muted' });
      expect(findBadge().classes().sort()).toEqual(
        [
          ...classes,
          'gl-shadow-inner-1-gray-400',
          'gl-max-w-full',
          'gl-text-truncate',
          'gl-bg-transparent!',
        ].sort(),
      );
      expect(findBadge().text()).toBe(text);
    },
  );

  it('does not render an unknown status', () => {
    createComponent({ props: { jobStatus: 'UNKNOWN_STATUS' } });

    expect(wrapper.html()).toBe('');
  });

  it('adds arbitrary attributes', () => {
    createComponent({ props: { jobStatus: JOB_STATUS_RUNNING }, attrs: { href: '/url' } });

    expect(findBadge().attributes('href')).toBe('/url');
  });
});
