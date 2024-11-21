import { GlIcon, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PipelineStatus, { i18n } from '~/ci/pipeline_editor/components/header/pipeline_status.vue';
import getPipelineQuery from '~/ci/pipeline_editor/graphql/queries/pipeline.query.graphql';
import getPipelineStatusQuery from '~/ci/pipeline_editor/graphql/queries/get_pipeline_status.query.graphql';
import PipelineMiniGraph from '~/ci/pipeline_mini_graph/pipeline_mini_graph.vue';
import PipelineEditorMiniGraph from '~/ci/pipeline_editor/components/header/pipeline_editor_mini_graph.vue';
import getPipelineEtag from '~/ci/pipeline_editor/graphql/queries/client/pipeline_etag.query.graphql';
import { mockCommitSha, mockProjectPipeline, mockProjectFullPath } from '../../mock_data';

Vue.use(VueApollo);

describe('Pipeline Status', () => {
  let wrapper;
  let mockApollo;
  let mockPipelineQuery;

  const createComponentWithApollo = ({ ciGraphqlPipelineMiniGraph = false } = {}) => {
    const handlers = [
      [getPipelineQuery, mockPipelineQuery],
      [getPipelineStatusQuery, mockPipelineQuery],
    ];
    mockApollo = createMockApollo(handlers);

    mockApollo.clients.defaultClient.cache.writeQuery({
      query: getPipelineEtag,
      data: {
        etags: {
          __typename: 'EtagValues',
          pipeline: 'pipelines/1',
        },
      },
    });

    wrapper = shallowMount(PipelineStatus, {
      apolloProvider: mockApollo,
      propsData: {
        commitSha: mockCommitSha,
      },
      provide: {
        glFeatures: {
          ciGraphqlPipelineMiniGraph,
        },
        projectFullPath: mockProjectFullPath,
      },
      stubs: { GlSprintf },
    });
  };

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findPipelineEditorMiniGraph = () => wrapper.findComponent(PipelineEditorMiniGraph);
  const findPipelineMiniGraph = () => wrapper.findComponent(PipelineMiniGraph);

  const findPipelineId = () => wrapper.find('[data-testid="pipeline-id"]');
  const findPipelineCommit = () => wrapper.find('[data-testid="pipeline-commit"]');
  const findPipelineErrorMsg = () => wrapper.find('[data-testid="pipeline-error-msg"]');
  const findPipelineLoadingMsg = () => wrapper.find('[data-testid="pipeline-loading-msg"]');
  const findPipelineViewBtn = () => wrapper.find('[data-testid="pipeline-view-btn"]');
  const findStatusIcon = () => wrapper.find('[data-testid="pipeline-status-icon"]');

  beforeEach(() => {
    mockPipelineQuery = jest.fn();
  });

  afterEach(() => {
    mockPipelineQuery.mockReset();
  });

  describe('loading icon', () => {
    it('renders while query is being fetched', () => {
      createComponentWithApollo();

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findPipelineLoadingMsg().text()).toBe(i18n.fetchLoading);
    });

    it('does not render if query is no longer loading', async () => {
      createComponentWithApollo();
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('when querying data', () => {
    describe('when data is set', () => {
      beforeEach(async () => {
        mockPipelineQuery.mockResolvedValue({
          data: { project: mockProjectPipeline() },
        });

        createComponentWithApollo();
        await waitForPromises();
      });

      it('query is called with correct variables', () => {
        expect(mockPipelineQuery).toHaveBeenCalledTimes(1);
        expect(mockPipelineQuery).toHaveBeenCalledWith({
          fullPath: mockProjectFullPath,
          sha: mockCommitSha,
        });
      });

      it('does not render error', () => {
        expect(findPipelineErrorMsg().exists()).toBe(false);
      });

      it('renders pipeline data', () => {
        const {
          id,
          commit: { title },
          detailedStatus: { detailsPath },
        } = mockProjectPipeline().pipeline;

        expect(findStatusIcon().exists()).toBe(true);
        expect(findPipelineId().text()).toBe(`#${id.match(/\d+/g)[0]}`);
        expect(findPipelineCommit().text()).toBe(`${mockCommitSha}: ${title}`);
        expect(findPipelineViewBtn().attributes('href')).toBe(detailsPath);
      });

      it('renders the pipeline mini graph', () => {
        expect(findPipelineEditorMiniGraph().exists()).toBe(true);
      });
    });

    describe('when data cannot be fetched', () => {
      beforeEach(async () => {
        mockPipelineQuery.mockRejectedValue(new Error());

        createComponentWithApollo();
        await waitForPromises();
      });

      it('renders error', () => {
        expect(findIcon().attributes('name')).toBe('warning-solid');
        expect(findPipelineErrorMsg().text()).toBe(i18n.fetchError);
      });

      it('does not render pipeline data', () => {
        expect(findStatusIcon().exists()).toBe(false);
        expect(findPipelineId().exists()).toBe(false);
        expect(findPipelineCommit().exists()).toBe(false);
        expect(findPipelineViewBtn().exists()).toBe(false);
      });
    });
  });

  describe('feature flag behavior', () => {
    beforeEach(() => {
      mockPipelineQuery.mockResolvedValue({
        data: { project: mockProjectPipeline() },
      });
    });

    it.each`
      state    | showLegacyPipelineMiniGraph | showPipelineMiniGraph
      ${true}  | ${false}                    | ${true}
      ${false} | ${true}                     | ${false}
    `(
      'renders the correct component when the feature flag is set to $state',
      async ({ state, showLegacyPipelineMiniGraph, showPipelineMiniGraph }) => {
        createComponentWithApollo({ ciGraphqlPipelineMiniGraph: state });

        await waitForPromises();

        expect(findPipelineEditorMiniGraph().exists()).toBe(showLegacyPipelineMiniGraph);
        expect(findPipelineMiniGraph().exists()).toBe(showPipelineMiniGraph);
      },
    );
  });
});
