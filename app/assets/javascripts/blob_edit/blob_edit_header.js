import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import BlobEditHeader from '~/repository/pages/blob_edit_header.vue';

export default function initBlobEditHeader(editor) {
  const el = document.querySelector('.js-blob-edit-header');

  if (!el) {
    return null;
  }

  const {
    updatePath,
    cancelPath,
    originalBranch,
    targetBranch,
    canPushCode,
    canPushToBranch,
    emptyRepo,
    isUsingLfs,
    blobName,
    branchAllowsCollaboration,
    lastCommitSha,
  } = el.dataset;

  return new Vue({
    el,
    provide: {
      editor,
      updatePath,
      cancelPath,
      originalBranch,
      targetBranch,
      blobName,
      lastCommitSha,
      emptyRepo: parseBoolean(emptyRepo),
      canPushCode: parseBoolean(canPushCode),
      canPushToBranch: parseBoolean(canPushToBranch),
      isUsingLfs: parseBoolean(isUsingLfs),
      branchAllowsCollaboration: parseBoolean(branchAllowsCollaboration),
    },
    render: (createElement) => createElement(BlobEditHeader),
  });
}
