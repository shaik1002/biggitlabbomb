import { uniqueId } from 'lodash';
import { findDesignWidget } from '../../utils';

export const findVersionId = (id) => (id.match('::Version/(.+$)') || [])[1];

export const findNoteId = (id) => (id.match('DiffNote/(.+$)') || [])[1];

export const extractDesigns = (data) =>
  findDesignWidget(data.project.workItems.nodes[0].widgets).designCollection.designs.nodes;

export const extractDesign = (data) => (extractDesigns(data) || [])[0];

export const extractVersions = (data) =>
  findDesignWidget(data.project.workItems.nodes[0].widgets).designCollection.versions.nodes;

export const extractDiscussions = (discussions) =>
  discussions.nodes.map((discussion, index) => ({
    ...discussion,
    index: index + 1,
    notes: discussion.notes.nodes,
  }));

export const getPageLayoutElement = () => document.querySelector('.layout-page');

export const designWidgetOf = (data) => findDesignWidget(data.workItem.widgets);

/**
 * Generates optimistic response for a design upload mutation
 * @param {Array<File>} files
 */
export const designUploadOptimisticResponse = (files) => {
  const designs = files.map((file) => ({
    __typename: 'Design',
    id: -uniqueId(),
    image: '',
    imageV432x230: '',
    description: '',
    descriptionHtml: '',
    filename: file.name,
    fullPath: '',
    imported: false,
    notesCount: 0,
    event: 'NONE',
    currentUserTodos: {
      __typename: 'TodoConnection',
      nodes: [],
    },
    diffRefs: {
      __typename: 'DiffRefs',
      baseSha: '',
      startSha: '',
      headSha: '',
    },
    discussions: {
      __typename: 'DesignDiscussion',
      nodes: [],
    },
    versions: {
      __typename: 'DesignVersionConnection',
      nodes: {
        __typename: 'DesignVersion',
        id: -uniqueId(),
        sha: -uniqueId(),
        createdAt: '',
        author: {
          __typename: 'UserCore',
          id: -uniqueId(),
          name: '',
          avatarUrl: '',
        },
      },
    },
  }));

  return {
    __typename: 'Mutation',
    designManagementUpload: {
      __typename: 'DesignManagementUploadPayload',
      designs,
      skippedDesigns: [],
      errors: [],
    },
  };
};
