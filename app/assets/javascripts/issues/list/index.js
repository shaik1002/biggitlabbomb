import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import IssuesListApp from 'ee_else_ce/issues/list/components/issues_list_app.vue';
import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsWorkItems from '~/behaviors/shortcuts/shortcuts_work_items';
import { parseBoolean } from '~/lib/utils/common_utils';
import JiraIssuesImportStatusApp from './components/jira_issues_import_status_app.vue';
import { gqlClient } from './graphql';

export async function mountJiraIssuesListApp() {
  const el = document.querySelector('.js-jira-issues-import-status-root');

  if (!el) {
    return null;
  }

  const { issuesPath, projectPath } = el.dataset;
  const canEdit = parseBoolean(el.dataset.canEdit);
  const isJiraConfigured = parseBoolean(el.dataset.isJiraConfigured);

  if (!isJiraConfigured || !canEdit) {
    return null;
  }

  Vue.use(VueApollo);

  return new Vue({
    el,
    name: 'JiraIssuesImportStatusRoot',
    apolloProvider: new VueApollo({
      defaultClient: await gqlClient(),
    }),
    render(createComponent) {
      return createComponent(JiraIssuesImportStatusApp, {
        props: {
          canEdit,
          isJiraConfigured,
          issuesPath,
          projectPath,
        },
      });
    },
  });
}

export async function mountIssuesListApp() {
  const el = document.querySelector('.js-issues-list-root');

  if (!el) {
    return null;
  }

  addShortcutsExtension(ShortcutsWorkItems);

  Vue.use(VueApollo);
  Vue.use(VueRouter);

  const {
    autocompleteAwardEmojisPath,
    calendarPath,
    canBulkUpdate,
    canCreateIssue,
    canCreateProjects,
    canEdit,
    canImportIssues,
    canReadCrmContact,
    canReadCrmOrganization,
    email,
    emailsHelpPagePath,
    emptyStateSvgPath,
    exportCsvPath,
    fullPath,
    groupPath,
    hasAnyIssues,
    hasAnyProjects,
    hasBlockedIssuesFeature,
    hasEpicsFeature,
    hasIssuableHealthStatusFeature,
    hasIssueDateFilterFeature,
    hasIssueWeightsFeature,
    hasIterationsFeature,
    hasScopedLabelsFeature,
    hasOkrsFeature,
    importCsvIssuesPath,
    initialEmail,
    initialSort,
    isIssueRepositioningDisabled,
    isProject,
    isPublicVisibilityRestricted,
    isSignedIn,
    jiraIntegrationPath,
    markdownHelpPath,
    maxAttachmentSize,
    newIssuePath,
    newProjectPath,
    projectImportJiraPath,
    quickActionsHelpPath,
    releasesPath,
    resetPath,
    rssPath,
    showNewIssueLink,
    signInPath,
    groupId = '',
    reportAbusePath,
    registerPath,
  } = el.dataset;

  return new Vue({
    el,
    name: 'IssuesListRoot',
    apolloProvider: new VueApollo({
      defaultClient: await gqlClient(),
    }),
    router: new VueRouter({
      base: window.location.pathname,
      mode: 'history',
      routes: [{ path: '/' }],
    }),
    provide: {
      autocompleteAwardEmojisPath,
      calendarPath,
      canBulkUpdate: parseBoolean(canBulkUpdate),
      canCreateIssue: parseBoolean(canCreateIssue),
      canCreateProjects: parseBoolean(canCreateProjects),
      canReadCrmContact: parseBoolean(canReadCrmContact),
      canReadCrmOrganization: parseBoolean(canReadCrmOrganization),
      emptyStateSvgPath,
      fullPath,
      projectPath: fullPath,
      groupPath,
      reportAbusePath,
      registerPath,
      hasAnyIssues: parseBoolean(hasAnyIssues),
      hasAnyProjects: parseBoolean(hasAnyProjects),
      hasBlockedIssuesFeature: parseBoolean(hasBlockedIssuesFeature),
      hasEpicsFeature: parseBoolean(hasEpicsFeature),
      hasIssuableHealthStatusFeature: parseBoolean(hasIssuableHealthStatusFeature),
      hasIssueDateFilterFeature: parseBoolean(hasIssueDateFilterFeature),
      hasIssueWeightsFeature: parseBoolean(hasIssueWeightsFeature),
      hasIterationsFeature: parseBoolean(hasIterationsFeature),
      hasScopedLabelsFeature: parseBoolean(hasScopedLabelsFeature),
      hasOkrsFeature: parseBoolean(hasOkrsFeature),
      initialSort,
      isIssueRepositioningDisabled: parseBoolean(isIssueRepositioningDisabled),
      isGroup: !parseBoolean(isProject),
      isProject: parseBoolean(isProject),
      isPublicVisibilityRestricted: parseBoolean(isPublicVisibilityRestricted),
      isSignedIn: parseBoolean(isSignedIn),
      jiraIntegrationPath,
      newIssuePath,
      newProjectPath,
      releasesPath,
      rssPath,
      showNewIssueLink: parseBoolean(showNewIssueLink),
      signInPath,
      // For CsvImportExportButtons component
      canEdit: parseBoolean(canEdit),
      email,
      exportCsvPath,
      importCsvIssuesPath,
      maxAttachmentSize,
      projectImportJiraPath,
      showExportButton: parseBoolean(hasAnyIssues),
      showImportButton: parseBoolean(canImportIssues),
      showLabel: !parseBoolean(hasAnyIssues),
      // For IssuableByEmail component
      emailsHelpPagePath,
      initialEmail,
      markdownHelpPath,
      quickActionsHelpPath,
      resetPath,
      groupId,
    },
    render: (createComponent) => createComponent(IssuesListApp),
  });
}
