import { FS_TYPE_BLOB, FS_TYPE_TREE } from '../../../../constants';

const createBaseFileObject = (type, { path = '', name = '' } = {}) => {
  return {
    type,
    timestamp: 0,
    path,
    name,
  };
};

export const createBlob = (...args) => {
  return {
    ...createBaseFileObject(FS_TYPE_BLOB, ...args),
    isLoaded: false,
    isLoading: false,
    content: '',
    isBinary: false,
    size: 0,
  };
};

export const createTree = (...args) => {
  return {
    ...createBaseFileObject(FS_TYPE_TREE, ...args),
    children: [],
    opened: false,
  };
};

export const createTreeChild = (type, name) => {
  return Object.freeze({ type, name });
};

export const getTreeChildSortKey = ({ type, name }) => `${type === 'tree' ? 0 : 1} ${name}`;
