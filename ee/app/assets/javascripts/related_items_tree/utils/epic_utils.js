import createGqClient from '~/lib/graphql';

import { ChildType, PathIdSeparator } from '../constants';

export const gqClient = createGqClient();

/**
 * Returns a numeric representation of item
 * order in an array.
 *
 * This method is to be used as comparision
 * function for Array.sort
 *
 * @param {cbject} childA
 * @param {object} childB
 */
export const sortChildren = (childA, childB) => childA.relativePosition - childB.relativePosition;

/**
 * Returns formatted child item to include additional
 * flags and properties to use while rendering tree.
 * @param {Object} item
 */
export const formatChildItem = item =>
  Object.assign({}, item, {
    pathIdSeparator: PathIdSeparator[item.type],
  });

/**
 * Returns formatted array of Epics that doesn't contain
 * `edges`->`node` nesting
 *
 * @param {Array} children
 */
export const extractChildEpics = children =>
  children.edges
    .map(({ node, epicNode = node }) =>
      formatChildItem({
        ...epicNode,
        fullPath: epicNode.group.fullPath,
        type: ChildType.Epic,
      }),
    )
    .sort(sortChildren);

/**
 * Returns formatted array of Assignees that doesn't contain
 * `edges`->`node` nesting
 *
 * @param {Array} assignees
 */
export const extractIssueAssignees = assignees =>
  assignees.edges.map(assigneeNode => ({
    ...assigneeNode.node,
  }));

/**
 * Returns formatted array of Issues that doesn't contain
 * `edges`->`node` nesting
 *
 * @param {Array} issues
 */
export const extractChildIssues = issues =>
  issues.edges
    .map(({ node, issueNode = node }) =>
      formatChildItem({
        ...issueNode,
        type: ChildType.Issue,
        assignees: extractIssueAssignees(issueNode.assignees),
      }),
    )
    .sort(sortChildren);

/**
 * Parses Graph query response and updates
 * children array to include issues within it
 * @param {Object} responseRoot
 */
export const processQueryResponse = ({ epic }) =>
  [].concat(extractChildEpics(epic.children), extractChildIssues(epic.issues));
