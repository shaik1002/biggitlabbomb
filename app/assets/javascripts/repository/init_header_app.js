import Vue from 'vue';
import { parseBoolean, convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import apolloProvider from './graphql';
import HeaderArea from './components/header_area.vue';
import createRouter from './router';

export default function initHeaderApp(isReadmeView = false) {
  const headerEl = document.getElementById('js-repository-blob-header-app');
  if (headerEl) {
    const {
      historyLink,
      ref,
      escapedRef,
      refType,
      projectId,
      breadcrumbsCanCollaborate,
      breadcrumbsCanEditTree,
      breadcrumbsCanPushCode,
      breadcrumbsSelectedBranch,
      breadcrumbsNewBranchPath,
      breadcrumbsNewTagPath,
      breadcrumbsNewBlobPath,
      breadcrumbsForkNewBlobPath,
      breadcrumbsForkNewDirectoryPath,
      breadcrumbsForkUploadBlobPath,
      breadcrumbsUploadPath,
      breadcrumbsNewDirPath,
      projectRootPath,
      comparePath,
      projectPath,
      webIdePromoPopoverImg,
      webIdeButtonOptions,
      sshUrl,
      httpUrl,
      xcodeUrl,
      kerberosUrl,
      downloadLinks,
      downloadArtifacts,
    } = headerEl.dataset;

    const {
      isFork,
      needsToFork,
      gitpodEnabled,
      isBlob,
      showEditButton,
      showWebIdeButton,
      showGitpodButton,
      showPipelineEditorUrl,
      webIdeUrl,
      editUrl,
      pipelineEditorUrl,
      gitpodUrl,
      userPreferencesGitpodPath,
      userProfileEnableGitpodPath,
    } = convertObjectPropsToCamelCase(JSON.parse(webIdeButtonOptions));

    // eslint-disable-next-line no-new
    new Vue({
      el: headerEl,
      provide: {
        canCollaborate: parseBoolean(breadcrumbsCanCollaborate),
        canEditTree: parseBoolean(breadcrumbsCanEditTree),
        canPushCode: parseBoolean(breadcrumbsCanPushCode),
        originalBranch: ref,
        selectedBranch: breadcrumbsSelectedBranch,
        newBranchPath: breadcrumbsNewBranchPath,
        newTagPath: breadcrumbsNewTagPath,
        newBlobPath: breadcrumbsNewBlobPath,
        forkNewBlobPath: breadcrumbsForkNewBlobPath,
        forkNewDirectoryPath: breadcrumbsForkNewDirectoryPath,
        forkUploadBlobPath: breadcrumbsForkUploadBlobPath,
        uploadPath: breadcrumbsUploadPath,
        newDirPath: breadcrumbsNewDirPath,
        projectRootPath,
        comparePath,
        isReadmeView,
        webIdePromoPopoverImg,
        isFork: parseBoolean(isFork),
        needsToFork: parseBoolean(needsToFork),
        gitpodEnabled: parseBoolean(gitpodEnabled),
        isBlob: parseBoolean(isBlob),
        showEditButton: parseBoolean(showEditButton),
        showWebIdeButton: parseBoolean(showWebIdeButton),
        showGitpodButton: parseBoolean(showGitpodButton),
        showPipelineEditorUrl: parseBoolean(showPipelineEditorUrl),
        webIdeUrl,
        editUrl,
        pipelineEditorUrl,
        gitpodUrl,
        userPreferencesGitpodPath,
        userProfileEnableGitpodPath,
        httpUrl,
        xcodeUrl,
        sshUrl,
        kerberosUrl,
        downloadLinks: downloadLinks ? JSON.parse(downloadLinks) : null,
        downloadArtifacts: downloadArtifacts ? JSON.parse(downloadArtifacts) : [],
      },
      apolloProvider,
      router: createRouter(projectPath, escapedRef),
      render(h) {
        return h(HeaderArea, {
          props: {
            refType,
            currentRef: ref,
            historyLink,
            // BlobControls:
            projectPath,
            // RefSelector:
            projectId,
          },
        });
      },
    });
  }
}
