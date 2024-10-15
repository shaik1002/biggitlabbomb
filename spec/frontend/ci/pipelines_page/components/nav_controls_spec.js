import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NavControls from '~/ci/pipelines_page/components/nav_controls.vue';

describe('Pipelines Nav Controls', () => {
  let wrapper;

  const createComponent = (props) => {
    wrapper = shallowMountExtended(NavControls, {
      propsData: {
        ...props,
      },
    });
  };

  const findRunPipelineButton = () => wrapper.findByTestId('run-pipeline-button');
  const findCiLintButton = () => wrapper.findByTestId('ci-lint-button');
  const findClearCacheButton = () => wrapper.findByTestId('clear-cache-button');

  it('should render link to create a new pipeline', () => {
    const mockData = {
      newPipelinePath: 'foo',
      ciLintPath: 'foo',
      resetCachePath: 'foo',
    };

    createComponent(mockData);

    const runPipelineButton = findRunPipelineButton();
    expect(runPipelineButton.text()).toContain('Run pipeline');
    expect(runPipelineButton.attributes('href')).toBe(mockData.newPipelinePath);
  });

  it('should not render link to create pipeline if no path is provided', () => {
    const mockData = {
      helpPagePath: 'foo',
      ciLintPath: 'foo',
      resetCachePath: 'foo',
    };

    createComponent(mockData);

    expect(findRunPipelineButton().exists()).toBe(false);
  });

  it('should render link for CI lint', () => {
    const mockData = {
      newPipelinePath: 'foo',
      helpPagePath: 'foo',
      ciLintPath: 'foo',
      resetCachePath: 'foo',
    };

    createComponent(mockData);
    const ciLintButton = findCiLintButton();

    expect(ciLintButton.text()).toContain('CI lint');
    expect(ciLintButton.attributes('href')).toBe(mockData.ciLintPath);
  });

  describe('Reset Runners Cache', () => {
    beforeEach(() => {
      const mockData = {
        newPipelinePath: 'foo',
        ciLintPath: 'foo',
        resetCachePath: 'foo',
      };
      createComponent(mockData);
    });

    it('should render button for resetting runner caches', () => {
      expect(findClearCacheButton().text()).toContain('Clear runner caches');
    });

    it('should emit postAction event when reset runner cache button is clicked', () => {
      findClearCacheButton().vm.$emit('click');

      expect(wrapper.emitted('resetRunnersCache')).toEqual([['foo']]);
    });
  });
});
