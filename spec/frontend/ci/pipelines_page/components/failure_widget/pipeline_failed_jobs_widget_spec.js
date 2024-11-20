import { GlBadge, GlButton } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PipelineFailedJobsWidget from '~/ci/pipelines_page/components/failure_widget/pipeline_failed_jobs_widget.vue';
import FailedJobsList from '~/ci/pipelines_page/components/failure_widget/failed_jobs_list.vue';
import getPipelineFailedJobsCount from '~/ci/pipelines_page/graphql/queries/get_pipeline_failed_jobs_count.query.graphql';
import { failedJobsCountMock } from './mock';

Vue.use(VueApollo);
jest.mock('~/alert');

describe('PipelineFailedJobsWidget component', () => {
  let wrapper;

  const defaultProps = {
    isPipelineActive: false,
    pipelineIid: 1,
    pipelinePath: '/pipelines/1',
    projectPath: 'namespace/project/',
  };

  const defaultProvide = {
    fullPath: 'namespace/project/',
    graphqlPath: 'api/graphql',
  };

  const defaultHandler = jest.fn().mockResolvedValue(failedJobsCountMock);

  const createMockApolloProvider = (handler) => {
    const requestHandlers = [[getPipelineFailedJobsCount, handler]];

    return createMockApollo(requestHandlers);
  };

  const createComponent = ({ props = {}, provide = {}, handler = defaultHandler } = {}) => {
    wrapper = shallowMountExtended(PipelineFailedJobsWidget, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        ...defaultProvide,
        ...provide,
      },
      stubs: { CrudComponent },
      apolloProvider: createMockApolloProvider(handler),
    });
  };

  const findFailedJobsButton = () => wrapper.findComponent(GlButton);
  const findFailedJobsList = () => wrapper.findComponent(FailedJobsList);
  const findCrudComponent = () => wrapper.findComponent(CrudComponent);
  const findCount = () => wrapper.findComponent(GlBadge);

  describe('when there are failed jobs', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
    });

    it('renders the show failed jobs button with correct count', () => {
      expect(findFailedJobsButton().exists()).toBe(true);
      expect(findCount().text()).toBe('4');
    });

    it('does not render the failed jobs widget', () => {
      expect(findFailedJobsList().exists()).toBe(false);
    });
  });

  const CSS_BORDER_CLASSES = 'is-collapsed gl-border-transparent hover:gl-border-default';

  describe('when the job button is clicked', () => {
    beforeEach(async () => {
      createComponent();

      await findFailedJobsButton().vm.$emit('click');
    });

    it('renders the failed jobs widget', () => {
      expect(findFailedJobsList().exists()).toBe(true);
    });

    it('removes the CSS border classes', () => {
      expect(findCrudComponent().attributes('class')).not.toContain(CSS_BORDER_CLASSES);
    });

    it('the failed jobs button has the correct "aria-expanded" attribute value', () => {
      expect(findFailedJobsButton().attributes('aria-expanded')).toBe('true');
    });
  });

  describe('when the job details are not expanded', () => {
    beforeEach(() => {
      createComponent();
    });

    it('has the CSS border classes', () => {
      expect(findCrudComponent().attributes('class')).toContain(CSS_BORDER_CLASSES);
    });

    it('the failed jobs button has the correct "aria-expanded" attribute value', () => {
      expect(findFailedJobsButton().attributes('aria-expanded')).toBe('false');
    });
  });

  describe('"aria-controls" attribute', () => {
    it('is set and identifies the correct element', () => {
      createComponent();

      expect(findFailedJobsButton().attributes('aria-controls')).toBe(
        'pipeline-failed-jobs-widget',
      );
      expect(findCrudComponent().attributes('id')).toBe('pipeline-failed-jobs-widget');
    });
  });

  describe('polling', () => {
    it('does not poll for failed jobs count when pipeline is inactive', async () => {
      createComponent();

      await waitForPromises();

      expect(defaultHandler).toHaveBeenCalledTimes(1);

      jest.advanceTimersByTime(10000);

      await waitForPromises();

      expect(defaultHandler).toHaveBeenCalledTimes(1);
    });

    it('polls for failed jobs count when pipeline is active', async () => {
      createComponent({ props: { isPipelineActive: true } });

      await waitForPromises();

      expect(defaultHandler).toHaveBeenCalledTimes(1);

      jest.advanceTimersByTime(10000);

      await waitForPromises();

      expect(defaultHandler).toHaveBeenCalledTimes(2);
    });
  });

  describe('job retry', () => {
    it('refetches failed jobs count', async () => {
      createComponent();

      await waitForPromises();

      expect(defaultHandler).toHaveBeenCalledTimes(1);

      await findFailedJobsButton().vm.$emit('click');

      findFailedJobsList().vm.$emit('job-retried');

      expect(defaultHandler).toHaveBeenCalledTimes(2);
    });
  });
});
