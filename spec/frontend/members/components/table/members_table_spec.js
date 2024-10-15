import { GlTable } from '@gitlab/ui';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import CreatedAt from '~/members/components/table/created_at.vue';
import ExpirationDatepicker from '~/members/components/table/expiration_datepicker.vue';
import MemberActions from '~/members/components/table/member_actions.vue';
import MemberAvatar from '~/members/components/table/member_avatar.vue';
import MemberSource from '~/members/components/table/member_source.vue';
import MemberActivity from '~/members/components/table/member_activity.vue';
import MembersTable from '~/members/components/table/members_table.vue';
import MembersPagination from '~/members/components/table/members_pagination.vue';
import MaxRole from '~/members/components/table/max_role.vue';
import {
  MEMBER_TYPES,
  MEMBER_STATE_CREATED,
  MEMBER_STATE_AWAITING,
  MEMBER_STATE_ACTIVE,
  USER_STATE_BLOCKED,
  BADGE_LABELS_AWAITING_SIGNUP,
  BADGE_LABELS_PENDING,
  TAB_QUERY_PARAM_VALUES,
} from '~/members/constants';
import {
  member as memberMock,
  directMember,
  invite,
  accessRequest,
  privateGroup,
  pagination,
} from '../../mock_data';

Vue.use(Vuex);

describe('MembersTable', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const createStore = (state = {}) => {
    return new Vuex.Store({
      modules: {
        [MEMBER_TYPES.invite]: {
          namespaced: true,
          state: {
            members: [],
            tableFields: [],
            tableAttrs: {
              tr: { 'data-testid': 'member-row' },
            },
            pagination,
            ...state,
          },
        },
      },
    });
  };

  const createComponent = (state, provide = {}) => {
    wrapper = mountExtended(MembersTable, {
      propsData: {
        tabQueryParamValue: TAB_QUERY_PARAM_VALUES.invite,
      },
      store: createStore(state),
      provide: {
        sourceId: 1,
        currentUserId: 1,
        canManageMembers: true,
        namespace: MEMBER_TYPES.invite,
        ...provide,
      },
      stubs: [
        'member-avatar',
        'member-source',
        'created-at',
        'member-actions',
        'max-role',
        'remove-group-link-modal',
        'remove-member-modal',
        'expiration-datepicker',
      ],
    });
  };

  const findTable = () => wrapper.findComponent(GlTable);
  const findTableCellByMemberId = (tableCellLabel, memberId) =>
    wrapper
      .findByTestId(`members-table-row-${memberId}`)
      .find(`[data-label="${tableCellLabel}"][role="cell"]`);

  describe('fields', () => {
    const memberCanUpdate = {
      ...directMember,
      canUpdate: true,
    };

    it.each`
      field           | label           | member             | expectedComponent
      ${'account'}    | ${'Account'}    | ${memberMock}      | ${MemberAvatar}
      ${'source'}     | ${'Source'}     | ${memberMock}      | ${MemberSource}
      ${'invited'}    | ${'Invited'}    | ${invite}          | ${CreatedAt}
      ${'requested'}  | ${'Requested'}  | ${accessRequest}   | ${CreatedAt}
      ${'maxRole'}    | ${'Max role'}   | ${memberCanUpdate} | ${MaxRole}
      ${'expiration'} | ${'Expiration'} | ${memberMock}      | ${ExpirationDatepicker}
      ${'activity'}   | ${'Activity'}   | ${memberMock}      | ${MemberActivity}
    `('renders the $label field', ({ field, label, member, expectedComponent }) => {
      createComponent({
        members: [member],
        tableFields: [field],
      });

      expect(wrapper.findByText(label, { selector: '[role="columnheader"] > div' }).exists()).toBe(
        true,
      );

      if (expectedComponent) {
        expect(
          wrapper
            .find(`[data-label="${label}"][role="cell"]`)
            .findComponent(expectedComponent)
            .exists(),
        ).toBe(true);
      }
    });

    describe('Invited column', () => {
      describe.each`
        state                    | userState             | expectedBadgeLabel
        ${MEMBER_STATE_CREATED}  | ${null}               | ${BADGE_LABELS_AWAITING_SIGNUP}
        ${MEMBER_STATE_CREATED}  | ${USER_STATE_BLOCKED} | ${BADGE_LABELS_PENDING}
        ${MEMBER_STATE_AWAITING} | ${''}                 | ${BADGE_LABELS_AWAITING_SIGNUP}
        ${MEMBER_STATE_AWAITING} | ${USER_STATE_BLOCKED} | ${BADGE_LABELS_PENDING}
        ${MEMBER_STATE_AWAITING} | ${'something_else'}   | ${BADGE_LABELS_PENDING}
        ${MEMBER_STATE_ACTIVE}   | ${null}               | ${''}
        ${MEMBER_STATE_ACTIVE}   | ${'something_else'}   | ${''}
      `('Invited Badge', ({ state, userState, expectedBadgeLabel }) => {
        it(`${
          expectedBadgeLabel ? 'shows' : 'hides'
        } invited badge if user status: '${userState}' and member state: '${state}'`, () => {
          createComponent({
            members: [
              {
                ...invite,
                state,
                invite: {
                  ...invite.invite,
                  userState,
                },
              },
            ],
            tableFields: ['invited'],
          });

          const invitedTab = wrapper.findByTestId('invited-badge');

          if (expectedBadgeLabel) {
            expect(invitedTab.text()).toBe(expectedBadgeLabel);
          } else {
            expect(invitedTab.exists()).toBe(false);
          }
        });
      });
    });

    describe('"Actions" field', () => {
      it('renders "Actions" field for screen readers', () => {
        createComponent({ members: [memberCanUpdate], tableFields: ['actions'] });

        const actionField = wrapper.findByTestId('col-actions');

        expect(actionField.exists()).toBe(true);
        expect(actionField.classes('gl-sr-only')).toBe(true);
        expect(
          wrapper.find(`[data-label="Actions"][role="cell"]`).findComponent(MemberActions).exists(),
        ).toBe(true);
      });

      describe('when user is not logged in', () => {
        it('does not render the "Actions" field', () => {
          createComponent({ tableFields: ['actions'] }, { currentUserId: null });

          expect(wrapper.findByTestId('col-actions').exists()).toBe(false);
        });
      });

      const memberCanRemove = {
        ...directMember,
        canRemove: true,
      };

      const memberCanRemoveBlockedLastOwner = {
        ...directMember,
        canRemove: false,
        isLastOwner: true,
      };

      const memberNoPermissions = {
        ...memberMock,
        id: 2,
      };

      describe.each`
        permission                       | members
        ${'canUpdate'}                   | ${[memberNoPermissions, memberCanUpdate]}
        ${'canRemove'}                   | ${[memberNoPermissions, memberCanRemove]}
        ${'canRemoveBlockedByLastOwner'} | ${[memberNoPermissions, memberCanRemoveBlockedLastOwner]}
        ${'canResend'}                   | ${[memberNoPermissions, invite]}
      `('when one of the members has $permission permissions', ({ members }) => {
        it('renders the "Actions" field', () => {
          createComponent({ members, tableFields: ['actions'] });

          expect(wrapper.findByTestId('col-actions').exists()).toBe(true);

          expect(findTableCellByMemberId('Actions', members[0].id).classes()).toStrictEqual([
            'col-actions',
            'gl-display-none!',
            'gl-lg-display-table-cell!',
            '!gl-align-middle',
          ]);
          expect(findTableCellByMemberId('Actions', members[1].id).classes()).toStrictEqual([
            'col-actions',
            '!gl-align-middle',
          ]);
        });
      });

      describe.each`
        permission                       | members
        ${'canUpdate'}                   | ${[memberMock]}
        ${'canRemove'}                   | ${[memberMock]}
        ${'canRemoveBlockedByLastOwner'} | ${[memberMock]}
        ${'canResend'}                   | ${[{ ...invite, invite: { ...invite.invite, canResend: false } }]}
      `('when none of the members have $permission permissions', ({ members }) => {
        it('does not render the "Actions" field', () => {
          createComponent({ members, tableFields: ['actions'] });

          expect(wrapper.findByTestId('col-actions').exists()).toBe(false);
        });
      });
    });

    describe('Source field', () => {
      beforeEach(() => {
        createComponent({
          members: [privateGroup],
          tableFields: ['source'],
        });
      });

      it('passes correct props to `MemberSource` component', () => {
        expect(wrapper.findComponent(MemberSource).props()).toMatchObject({
          memberSource: {},
          isDirectMember: true,
          isSharedWithGroupPrivate: true,
          createdBy: null,
        });
      });
    });
  });

  describe('when `members` is an empty array', () => {
    it('displays a "No members found" message', () => {
      createComponent();

      expect(wrapper.findByText('No members found').exists()).toBe(true);
    });
  });

  it('adds QA testid to table row', () => {
    createComponent();

    expect(findTable().find('tbody tr').attributes('data-testid')).toBe('member-row');
  });

  it('renders `members-pagination` component with correct props', () => {
    createComponent();
    const membersPagination = wrapper.findComponent(MembersPagination);

    expect(membersPagination.props()).toMatchObject({
      pagination,
      tabQueryParamValue: TAB_QUERY_PARAM_VALUES.invite,
    });
  });
});
