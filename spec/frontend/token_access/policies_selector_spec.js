import {
  GlSkeletonLoader,
  GlTableLite,
  GlAlert,
  GlFormRadio,
  GlFormRadioGroup,
  GlCollapsibleListbox,
} from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PoliciesSelector, {
  PERMISSION_OPTION_DEFAULT,
  PERMISSION_OPTION_FINE_GRAINED,
  TABLE_FIELDS,
} from '~/token_access/components/policies_selector.vue';
import jobTokenPoliciesByCategoryQuery from '~/token_access/graphql/queries/job_token_policies_by_category.query.graphql';
import { stubComponent } from 'helpers/stub_component';
import { jobTokenPoliciesByCategory } from './mock_data';

Vue.use(VueApollo);

describe('Policies selector component', () => {
  let wrapper;

  const defaultPoliciesHandler = jest.fn().mockResolvedValue({
    data: { jobTokenPoliciesByCategory },
  });

  const createWrapper = ({
    policiesHandler = defaultPoliciesHandler,
    value = [],
    disabled = false,
    stubs = {},
  } = {}) => {
    wrapper = mountExtended(PoliciesSelector, {
      apolloProvider: createMockApollo([[jobTokenPoliciesByCategoryQuery, policiesHandler]]),
      propsData: { value, disabled },
      stubs,
    });

    return waitForPromises();
  };

  const getCategoryIndex = (category) => jobTokenPoliciesByCategory.indexOf(category);

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findTable = () => wrapper.findComponent(GlTableLite);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);
  const findDefaultRadio = () => wrapper.findByTestId('default-radio');
  const findFineGrainedRadio = () => wrapper.findByTestId('fine-grained-radio');
  const findNameForCategory = (category) =>
    findTable().findAll('tbody tr').at(getCategoryIndex(category)).findAll('td').at(0);
  const findPolicyDropdownForCategory = (category) =>
    wrapper.findAllComponents(GlCollapsibleListbox).at(getCategoryIndex(category));

  describe('permission type radio options', () => {
    beforeEach(() =>
      createWrapper({
        stubs: {
          GlFormRadioGroup: stubComponent(GlFormRadioGroup, { props: ['checked'] }),
          GlFormRadio: stubComponent(GlFormRadio, {
            template: '<div><slot></slot><slot name="help"></slot></div>',
          }),
        },
      }),
    );

    describe('radio group', () => {
      it('shows radio group', () => {
        expect(findRadioGroup().exists()).toBe(true);
      });

      it.each`
        value   | type
        ${null} | ${PERMISSION_OPTION_DEFAULT}
        ${[]}   | ${PERMISSION_OPTION_FINE_GRAINED}
      `('selects the $type option when the value prop is $value', async ({ value, type }) => {
        await wrapper.setProps({ value });

        expect(findRadioGroup().props('checked')).toBe(type);
      });

      it.each`
        type                              | value
        ${PERMISSION_OPTION_DEFAULT}      | ${null}
        ${PERMISSION_OPTION_FINE_GRAINED} | ${[]}
      `('emits input event with $value when $type is selected', ({ type, value }) => {
        findRadioGroup().vm.$emit('change', type);

        expect(wrapper.emitted('input').at(-1)[0]).toEqual(value);
      });
    });

    it.each`
      type                              | findRadio               | expectedText
      ${PERMISSION_OPTION_DEFAULT}      | ${findDefaultRadio}     | ${'Default permissions Use the standard permissions model based on user membership and roles'}
      ${PERMISSION_OPTION_FINE_GRAINED} | ${findFineGrainedRadio} | ${'Fine-grained permissions Apply permissions that grant access to individual resources'}
    `('shows the $type radio', ({ type, findRadio, expectedText }) => {
      expect(findRadio().text()).toMatchInterpolatedText(expectedText);
      expect(findRadio().attributes('value')).toBe(type);
    });
  });

  describe('when Default permissions is selected', () => {
    beforeEach(() => createWrapper({ value: null }));

    it('does not run policies query', () => {
      expect(defaultPoliciesHandler).not.toHaveBeenCalled();
    });

    it('does not show policies table', () => {
      expect(findTable().exists()).toBe(false);
    });
  });

  describe('when Fine-grained permissions is selected', () => {
    beforeEach(() => {
      createWrapper({
        stubs: { GlTableLite: stubComponent(GlTableLite, { props: ['fields', 'items'] }) },
      });
    });

    it('runs policies query', () => {
      expect(defaultPoliciesHandler).toHaveBeenCalledTimes(1);
    });

    describe('when policies query is loading', () => {
      it('shows skeleton loader', () => {
        expect(findSkeletonLoader().exists()).toBe(true);
      });

      it('does not show policies table', () => {
        expect(findTable().exists()).toBe(false);
      });

      it('does not show error alert', () => {
        expect(findAlert().exists()).toBe(false);
      });
    });

    describe('when policies query is done', () => {
      beforeEach(() => waitForPromises());

      it('does not show skeleton loader', () => {
        expect(findSkeletonLoader().exists()).toBe(false);
      });

      it('does not show error alert', () => {
        expect(findAlert().exists()).toBe(false);
      });

      it('shows policies table', () => {
        expect(findTable().props()).toMatchObject({
          items: jobTokenPoliciesByCategory,
          fields: TABLE_FIELDS,
        });
      });
    });

    describe('policies table', () => {
      beforeEach(() => createWrapper());

      describe.each(jobTokenPoliciesByCategory)('for category $text', (category) => {
        const policies = [{ text: 'None', value: '' }, ...category.policies];

        it('shows the category name', () => {
          expect(findNameForCategory(category).text()).toBe(category.text);
        });

        it('shows the category dropdown', () => {
          expect(findPolicyDropdownForCategory(category).props('items')).toEqual(policies);
        });

        it.each(policies)(`selects the $text policy when it is selected`, async (policy) => {
          const dropdown = findPolicyDropdownForCategory(category);
          dropdown.vm.$emit('select', policy.value);
          await nextTick();

          expect(dropdown.props('selected')).toBe(policy.value);
        });
      });

      describe('when multiple policies are selected across categories', () => {
        const expectedPolicies = ['ADMIN_CONTAINERS', 'ADMIN_DEPLOYMENTS'];

        beforeEach(() => {
          jobTokenPoliciesByCategory.forEach((category) => {
            const policy = category.policies.at(-1).value;
            findPolicyDropdownForCategory(category).vm.$emit('select', policy);
          });
        });

        it('allows multiple policies to be selected', () => {
          jobTokenPoliciesByCategory.forEach((category) => {
            expect(findPolicyDropdownForCategory(category).props('selected')).toBe(
              category.policies.at(-1).value,
            );
          });
        });

        it('emits selected policies', () => {
          expect(wrapper.emitted('input').at(-1)[0]).toEqual(expectedPolicies);
        });

        it('keeps selected policies when permission type is toggled from fine-grained to default, then back to fine-grained again', () => {
          findRadioGroup().vm.$emit('change', PERMISSION_OPTION_DEFAULT);
          findRadioGroup().vm.$emit('change', PERMISSION_OPTION_FINE_GRAINED);

          expect(wrapper.emitted('input').at(-1)[0]).toEqual(expectedPolicies);
        });
      });
    });

    describe('when policies query fails', () => {
      beforeEach(() =>
        createWrapper({ policiesHandler: jest.fn().mockRejectedValue(new Error('some error')) }),
      );

      it('does not show skeleton loader', () => {
        expect(findSkeletonLoader().exists()).toBe(false);
      });

      it('does not show policies table', () => {
        expect(findTable().exists()).toBe(false);
      });

      it('shows error alert', () => {
        expect(findAlert().text()).toBe('some error');
        expect(findAlert().props()).toMatchObject({
          variant: 'danger',
          dismissible: false,
        });
      });
    });

    describe('disabled prop', () => {
      describe.each([true, false])('when disabled prop is %s', (disabled) => {
        beforeEach(() =>
          createWrapper({
            disabled,
            stubs: { GlFormRadioGroup: stubComponent(GlFormRadioGroup, { props: ['disabled'] }) },
          }),
        );

        it(`sets radio group disabled to ${disabled}`, () => {
          expect(findRadioGroup().props('disabled')).toBe(disabled);
        });

        it(`sets all policy dropdowns disabled to ${disabled}`, () => {
          wrapper.findAllComponents(GlCollapsibleListbox).wrappers.forEach((dropdown) => {
            expect(dropdown.props('disabled')).toBe(disabled);
          });
        });
      });
    });
  });
});
