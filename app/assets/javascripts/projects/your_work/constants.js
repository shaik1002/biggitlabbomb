import { __ } from '~/locale';
import contributedProjectsQuery from './graphql/queries/contributed_projects.query.graphql';
import personalProjectsQuery from './graphql/queries/personal_projects.query.graphql';
import membershipProjectsQuery from './graphql/queries/membership_projects.query.graphql';
import starredProjectsQuery from './graphql/queries/starred_projects.query.graphql';
import inactiveProjectsQuery from './graphql/queries/inactive_projects.query.graphql';

export const CONTRIBUTED_TAB = {
  text: __('Contributed'),
  value: 'contributed',
  query: contributedProjectsQuery,
  queryPath: 'currentUser.contributedProjects',
};

export const STARRED_TAB = {
  text: __('Starred'),
  value: 'starred',
  query: starredProjectsQuery,
  queryPath: 'currentUser.starredProjects',
};

export const PERSONAL_TAB = {
  text: __('Personal'),
  value: 'personal',
  query: personalProjectsQuery,
  queryPath: 'projects',
};

export const MEMBER_TAB = {
  text: __('Member'),
  value: 'member',
  query: membershipProjectsQuery,
  queryPath: 'projects',
};

export const INACTIVE_TAB = {
  text: __('Inactive'),
  value: 'inactive',
  query: inactiveProjectsQuery,
  queryPath: 'projects',
};

export const PROJECT_DASHBOARD_TABS = [
  CONTRIBUTED_TAB,
  STARRED_TAB,
  PERSONAL_TAB,
  MEMBER_TAB,
  INACTIVE_TAB,
];

export const BASE_ROUTE = '/dashboard/projects';

export const ROOT_ROUTE_NAME = 'root';

export const DASHBOARD_ROUTE_NAME = 'dashboard';

export const PROJECTS_DASHBOARD_ROUTE_NAME = 'projects-dashboard';

export const CUSTOM_DASHBOARD_ROUTE_NAMES = [
  ROOT_ROUTE_NAME,
  DASHBOARD_ROUTE_NAME,
  PROJECTS_DASHBOARD_ROUTE_NAME,
];

export const FILTERED_SEARCH_NAMESPACE = 'dashboard';
export const FILTERED_SEARCH_TERM_KEY = 'name';
