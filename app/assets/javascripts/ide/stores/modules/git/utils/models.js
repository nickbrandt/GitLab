import { FS_TYPE_TREE, FS_TYPE_BLOB } from '../../../../constants';
import { hash } from './hash';

export const createGitObjectBlob = file => {
  return Object.freeze({
    type: FS_TYPE_BLOB,
    data: Object.freeze({
      isLoaded: file.isLoaded,
      content: file.content,
    }),
  });
};

const getBlobDataKey = ({ isLoaded, content }) => `${isLoaded} ${content}`;

export const createGitObjectTreeChild = ({ type, name, key }) => {
  return Object.freeze({
    type,
    name,
    key,
  });
};

export const createGitObjectTree = file => {
  return Object.freeze({
    type: FS_TYPE_TREE,
    data: Object.freeze({
      children: file.children.map(createGitObjectTreeChild),
    }),
  });
};

const getTreeDataKey = ({ children }) =>
  children.map(({ type, name, key }) => `${type} ${name} ${key}`).join(' ');

export const hashGitObject = ({ type, data }) => {
  const dataKey = type === FS_TYPE_TREE ? getTreeDataKey(data) : getBlobDataKey(data);

  return hash(`${type} ${dataKey}`);
};
