import { sortedIndexBy } from 'lodash';
import { createTreeChild, getTreeChildSortKey } from './models';

/* eslint-disable import/prefer-default-export */
export const insertIntoTree = (tree, type, name) => {
  const entry = createTreeChild(type, name);

  const idx = sortedIndexBy(tree.children, entry, getTreeChildSortKey);

  tree.children.splice(idx, 0, entry);
};

export const removeFromTree = (tree, child) => {
  const idx = sortedIndexBy(tree.children, child, getTreeChildSortKey);

  if (getTreeChildSortKey(tree.children[idx]) !== getTreeChildSortKey(child)) {
    return;
  }

  tree.children.splice(idx, 1);
};
