import organizationUsersResponse from 'test_fixtures/graphql/organizations/organization_users.query.graphql.json';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

const {
  data: {
    organization: {
      organizationUsers: { nodes: users },
    },
  },
} = organizationUsersResponse;

export const MOCK_PATHS = {
  adminUser: '/admin/users/:id',
};

export const MOCK_USERS_FORMATTED = users.map(({ badges, user }) => {
  return { ...user, id: getIdFromGraphQLId(user.id), badges, email: user.publicEmail };
});
