export const createFile = (path, content = '') => ({
  id: path,
  path,
  content,
  raw: content,
});

export const createNewFile = (path, content) =>
  Object.assign(createFile(path, content), {
    tempFile: true,
    raw: '',
  });

export const createDeletedFile = (path, content) =>
  Object.assign(createFile(path, content), {
    deleted: true,
  });

export const createUpdatedFile = (path, oldContent, content) =>
  Object.assign(createFile(path, content), {
    raw: oldContent,
  });

export const createMovedFile = (path, prevPath, content) =>
  Object.assign(createNewFile(path, content), {
    prevPath,
  });
