import { sortedIndexBy } from 'lodash';

const getTreeEntryKey = ({ type, name }) => `${type === 'tree' ? 0 : 1} ${name}`;

/* eslint-disable import/prefer-default-export */
export const insertIntoTree = (tree, type, name) => {
  const entry = { type, name };

  const idx = sortedIndexBy(tree.children, entry, getTreeEntryKey);

  tree.children.splice(idx, 0, entry);
};
