import { shallowMount } from '@vue/test-utils';
import IssueHealthStatus from 'ee/related_items_tree/components/issue_health_status.vue';
import WorkItemHealthStatus from '~/work_items/components/work_item_health_status.vue';
import { WIDGET_TYPE_HEALTH_STATUS } from '~/work_items/constants';

describe('WorkItemHealthStatus', () => {
  let wrapper;

  const issueObject = {
    healthStatus: 'onTrack',
  };

  const workItemObject = {
    widgets: [
      {
        type: WIDGET_TYPE_HEALTH_STATUS,
        healthStatus: 'onTrack',
      },
    ],
  };

  const findIssueHealthStatus = () => wrapper.findComponent(IssueHealthStatus);

  const mountComponent = ({ issue, hasIssuableHealthStatusFeature = false } = {}) =>
    shallowMount(WorkItemHealthStatus, {
      provide: { hasIssuableHealthStatusFeature },
      propsData: { issue },
    });

  describe.each`
    type           | obj
    ${'issue'}     | ${issueObject}
    ${'work item'} | ${workItemObject}
  `('with $type object', ({ obj }) => {
    describe('health status', () => {
      describe('when hasIssuableHealthStatusFeature=true', () => {
        it('renders IssueHealthStatus', () => {
          wrapper = mountComponent({ issue: obj, hasIssuableHealthStatusFeature: true });

          expect(findIssueHealthStatus().props('healthStatus')).toBe('onTrack');
        });

        it('displays the health status container', () => {
          wrapper = mountComponent({ issue: obj, hasIssuableHealthStatusFeature: true });

          expect(wrapper.find('.gl-flex.gl-items-center').exists()).toBe(true);
        });
      });

      describe('when hasIssuableHealthStatusFeature=false', () => {
        it('does not render IssueHealthStatus', () => {
          wrapper = mountComponent({ issue: obj, hasIssuableHealthStatusFeature: false });

          expect(findIssueHealthStatus().exists()).toBe(false);
        });

        it('does not display the health status container', () => {
          wrapper = mountComponent({ issue: obj, hasIssuableHealthStatusFeature: false });

          expect(wrapper.find('.gl-flex.gl-items-center').exists()).toBe(false);
        });
      });

      describe('when no health status is available', () => {
        it('does not render IssueHealthStatus', () => {
          const issueWithoutHealthStatus = {};
          wrapper = mountComponent({
            issue: issueWithoutHealthStatus,
            hasIssuableHealthStatusFeature: true,
          });

          expect(findIssueHealthStatus().exists()).toBe(false);
        });
      });
    });
  });
});
