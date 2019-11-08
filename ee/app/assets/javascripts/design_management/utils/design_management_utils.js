import { s__ } from '~/locale';
import createFlash from '~/flash';

/**
 * Returns formatted array that doesn't contain
 * `edges`->`node` nesting
 *
 * @param {Array} elements
 */

export const extractNodes = elements => elements.edges.map(({ node }) => node);

/**
 * Returns formatted array of discussions that doesn't contain
 * `edges`->`node` nesting for child notes
 *
 * @param {Array} discussions
 */

export const extractDiscussions = discussions =>
  discussions.edges.map(discussion => {
    const discussionNode = { ...discussion.node };
    discussionNode.notes = extractNodes(discussionNode.notes);
    return discussionNode;
  });

/**
 * Returns a discussion with the given id from discussions array
 *
 * @param {Array} discussions
 */

export const extractCurrentDiscussion = (discussions, id) =>
  discussions.edges.find(({ node }) => node.id === id);

const deleteDesignsFromStore = (store, query, selectedDesigns) => {
  const data = store.readQuery(query);

  const changedDesigns = data.project.issue.designCollection.designs.edges.filter(
    ({ node }) => !selectedDesigns.includes(node.filename),
  );
  data.project.issue.designCollection.designs.edges = [...changedDesigns];

  store.writeQuery({
    ...query,
    data,
  });
};

const addNewVersionToStore = (store, query, version) => {
  if (!version) return;

  const data = store.readQuery(query);
  const newEdge = { node: version, __typename: 'DesignVersionEdge' };

  data.project.issue.designCollection.versions.edges = [
    newEdge,
    ...data.project.issue.designCollection.versions.edges,
  ];

  store.writeQuery({
    ...query,
    data,
  });
};

export const onDesignDeletionError = e => {
  createFlash(s__('DesignManagement|We could not delete design(s). Please try again.'));
  throw e;
};

export const updateStoreAfterDesignsDelete = (store, data, query, designs) => {
  if (data.errors) {
    onDesignDeletionError(new Error(data.errors));
  } else {
    deleteDesignsFromStore(store, query, designs);
    addNewVersionToStore(store, query, data.version);
  }
};

export const findVersionId = id => id.match('::Version/(.+$)')[1];
