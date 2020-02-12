/* eslint no-param-reassign: ["error", { "props": false }] */

import produce from 'immer';
import createFlash from '~/flash';
import { extractCurrentDiscussion, extractDesign } from './design_management_utils';
import {
  ADD_IMAGE_DIFF_NOTE_ERROR,
  ADD_DISCUSSION_COMMENT_ERROR,
  UPLOAD_DESIGN_ERROR,
  designDeletionError,
} from './error_messages';

const designsOf = data => data.project.issue.designCollection.designs;

const isParticipating = (design, username) =>
  design.issue.participants.edges.some(participant => participant.node.username === username);

const deleteDesignsFromStore = (store, query, selectedDesigns) => {
  const sourceData = store.readQuery(query);

  const data = produce(sourceData, draftData => {
    const changedDesigns = designsOf(sourceData).edges.filter(
      ({ node }) => !selectedDesigns.includes(node.filename),
    );
    designsOf(draftData).edges = [...changedDesigns];
  });

  store.writeQuery({
    ...query,
    data,
  });
};

/**
 * Adds a new version of designs to store
 *
 * @param {Object} store
 * @param {Object} query
 * @param {Object} version
 */
const addNewVersionToStore = (store, query, version) => {
  if (!version) return;

  const sourceData = store.readQuery(query);

  const newVersion = { node: version, __typename: 'DesignVersionEdge' };

  const data = produce(sourceData, draftData => {
    draftData.project.issue.designCollection.versions.edges.unshift(newVersion);
  });

  store.writeQuery({
    ...query,
    data,
  });
};

const addDiscussionCommentToStore = (store, createNote, query, queryVariables, discussionId) => {
  const sourceData = store.readQuery({
    query,
    variables: queryVariables,
  });

  const newParticipant = {
    __typename: 'UserEdge',
    node: {
      // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
      __typename: 'User',
      ...createNote.note.author,
    },
  };

  const data = produce(sourceData, draftData => {
    const design = extractDesign(draftData);
    const currentDiscussion = extractCurrentDiscussion(design.discussions, discussionId);
    currentDiscussion.node.notes.edges.push({
      __typename: 'NoteEdge',
      node: createNote.note,
    });

    if (!isParticipating(design, createNote.note.author.username)) {
      design.issue.participants.edges.push(newParticipant);
    }

    design.notesCount += 1;
  });

  store.writeQuery({
    query,
    variables: queryVariables,
    data,
  });
};

const addImageDiffNoteToStore = (store, createImageDiffNote, query, variables) => {
  const sourceData = store.readQuery({
    query,
    variables,
  });

  const newDiscussion = {
    __typename: 'DiscussionEdge',
    node: {
      // False positive i18n lint: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26
      // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
      __typename: 'Discussion',
      id: createImageDiffNote.note.discussion.id,
      replyId: createImageDiffNote.note.discussion.replyId,
      notes: {
        __typename: 'NoteConnection',
        edges: [
          {
            __typename: 'NoteEdge',
            node: createImageDiffNote.note,
          },
        ],
      },
    },
  };

  const newParticipant = {
    __typename: 'UserEdge',
    node: {
      // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
      __typename: 'User',
      ...createImageDiffNote.note.author,
    },
  };

  const data = produce(sourceData, draftData => {
    const design = extractDesign(draftData);
    design.discussions.edges.push(newDiscussion);

    if (!isParticipating(design, createImageDiffNote.note.author.username)) {
      design.issue.participants.edges.push(newParticipant);
    }

    design.notesCount += 1;
  });

  store.writeQuery({
    query,
    variables,
    data,
  });
};

const addNewDesignToStore = (store, designManagementUpload, query) => {
  const sourceData = store.readQuery(query);

  const newDesigns = designsOf(sourceData).edges.reduce((acc, design) => {
    if (!acc.find(d => d.filename === design.node.filename)) {
      acc.push(design.node);
    }

    return acc;
  }, designManagementUpload.designs);

  let newVersionNode;
  const findNewVersions = designManagementUpload.designs.find(design => design.versions);

  if (findNewVersions) {
    const findNewVersionsEdges = findNewVersions.versions.edges;

    if (findNewVersionsEdges && findNewVersionsEdges.length) {
      newVersionNode = [findNewVersionsEdges[0]];
    }
  }

  const newVersions = [
    ...(newVersionNode || []),
    ...sourceData.project.issue.designCollection.versions.edges,
  ];

  const updatedDesigns = {
    __typename: 'DesignCollection',
    designs: {
      __typename: 'DesignConnection',
      edges: newDesigns.map(design => ({
        __typename: 'DesignEdge',
        node: design,
      })),
    },
    versions: {
      __typename: 'DesignVersionConnection',
      edges: newVersions,
    },
  };

  const data = produce(sourceData, draftData => {
    draftData.project.issue.designCollection = updatedDesigns;
  });

  store.writeQuery({
    ...query,
    data,
  });
};

const onError = (data, message) => {
  createFlash(message);
  throw new Error(data.errors);
};

const hasErrors = ({ errors = [] }) => errors?.length;

/**
 * Updates a store after design deletion
 *
 * @param {Object} store
 * @param {Object} data
 * @param {Object} query
 * @param {Array} designs
 */
export const updateStoreAfterDesignsDelete = (store, data, query, designs) => {
  if (hasErrors(data)) {
    onError(data, designDeletionError({ singular: designs.length === 1 }));
  } else {
    deleteDesignsFromStore(store, query, designs);
    addNewVersionToStore(store, query, data.version);
  }
};

export const updateStoreAfterAddDiscussionComment = (
  store,
  data,
  query,
  queryVariables,
  discussionId,
) => {
  if (hasErrors(data)) {
    onError(data, ADD_DISCUSSION_COMMENT_ERROR);
  } else {
    addDiscussionCommentToStore(store, data, query, queryVariables, discussionId);
  }
};

export const updateStoreAfterAddImageDiffNote = (store, data, query, queryVariables) => {
  if (hasErrors(data)) {
    onError(data, ADD_IMAGE_DIFF_NOTE_ERROR);
  } else {
    addImageDiffNoteToStore(store, data, query, queryVariables);
  }
};

export const updateStoreAfterUploadDesign = (store, data, query) => {
  if (hasErrors(data)) {
    onError(data, UPLOAD_DESIGN_ERROR);
  } else {
    addNewDesignToStore(store, data, query);
  }
};
