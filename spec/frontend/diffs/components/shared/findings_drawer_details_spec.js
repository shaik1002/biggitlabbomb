import FindingsDrawerDetails from '~/diffs/components/shared/findings_drawer_details.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import {
  mockFindingDetails,
  mockFindingDetected,
  mockFindingDismissed,
  mockFindingsMultiple,
  mockProject,
} from '../../mock_data/findings_drawer';

describe('Findings Drawer Details', () => {
  let wrapper;

  const findingDetailsProps = {
    drawer: mockFindingDetected,
    project: mockProject,
  };

  const createWrapper = (
    findingDetailsOverrides = {},
    { vulnerabilityCodeFlow = false, mrVulnerabilityCodeFlow = false } = {},
  ) => {
    const propsData = {
      drawer: findingDetailsProps.drawer,
      project: findingDetailsProps.project,
      insideTab: false,
      ...findingDetailsOverrides,
    };

    wrapper = mountExtended(FindingsDrawerDetails, {
      propsData,
      provide: {
        glFeatures: { vulnerabilityCodeFlow, mrVulnerabilityCodeFlow },
      },
    });
  };

  const getById = (id) => wrapper.findByTestId(id);
  const findTitle = () => wrapper.findByTestId('findings-drawer-title');

  describe('General Rendering', () => {
    it('renders without errors', () => {
      createWrapper();
      expect(wrapper.exists()).toBe(true);
    });

    it('matches the snapshot with dismissed badge', () => {
      createWrapper();
      expect(wrapper.element).toMatchSnapshot();
    });

    it('matches the snapshot with detected badge', () => {
      createWrapper();
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('Active Index Handling', () => {
    it('watcher sets active index on drawer prop change', () => {
      createWrapper({ drawer: mockFindingsMultiple[2] });
      expect(findTitle().props().value).toBe(mockFindingsMultiple[2].title);
    });
  });

  describe('when `vulnerabilityCodeFlow` and `mrVulnerabilityCodeFlow` are enabled', () => {
    describe('when `details` object is not empty', () => {
      beforeEach(() => {
        createWrapper(
          {
            insideTab: true,
            drawer: {
              ...mockFindingDismissed,
              details: mockFindingDetails,
            },
          },
          {
            vulnerabilityCodeFlow: true,
            mrVulnerabilityCodeFlow: true,
          },
        );
      });

      it('should add class `gl-pl-0`', () => {
        expect(getById('drawer-container').classes('gl-pl-0')).toBe(true);
      });

      it('should show code flow button', () => {
        expect(getById('code-flow-button').exists()).toBe(true);
      });
    });

    describe('when `details` object is empty', () => {
      beforeEach(() => {
        createWrapper(
          { insideTab: false },
          {
            vulnerabilityCodeFlow: true,
            mrVulnerabilityCodeFlow: true,
          },
        );
      });

      it('should not add class `gl-pl-0`', () => {
        expect(getById('drawer-container').classes('gl-pl-0')).toBe(false);
      });

      it('should not show code flow button', () => {
        expect(getById('code-flow-button').exists()).toBe(false);
      });
    });
  });

  describe('when `vulnerabilityCodeFlow` and `mrVulnerabilityCodeFlow` are disabled', () => {
    beforeEach(() => {
      createWrapper(
        {},
        {
          vulnerabilityCodeFlow: false,
          mrVulnerabilityCodeFlow: false,
        },
      );
    });

    it('should add class `gl-pl-0`', () => {
      expect(getById('drawer-container').classes('gl-pl-0')).toBe(false);
    });

    it('should not show code flow button', () => {
      expect(getById('code-flow-button').exists()).toBe(false);
    });
  });
});
