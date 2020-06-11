/* eslint-disable import/prefer-default-export */
export const splitPath = path => {
  const idx = path.lastIndexOf('/');

  return idx < 0 ? ['', path] : [path.slice(0, idx) || '', path.slice(idx + 1)];
};

export const getParentPaths = path =>
  path
    .split('/')
    .reduce((acc, item, idx) => acc.concat(!idx ? item : `${acc[idx - 1]}/${item}`), [])
    .slice(0, -1);
