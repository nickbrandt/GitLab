import {
  findByTitle,
  findAllByText,
  getByText,
  findByLabelText,
  screen,
  fireEvent,
} from '@testing-library/dom';

const isFileRowOpen = row => row.matches('.is-open');

const getLeftSidebar = async () => screen.getByTestId('left-sidebar');

const findMonacoEditorTextarea = async () => screen.findByLabelText(/Editor content;/);

const findMonacoEditor = async () => (await findMonacoEditorTextarea()).closest('.monaco-editor');

const findTreeBody = async () => screen.findByTestId('ide-tree-body', {}, { timeout: 5000 });

const findTreeActions = async () => screen.findByTestId('ide-tree-actions');

const findFileRowContainer = async (row = null) => (row ? row.parentElement : findTreeBody());

const findFileRow = async (name, row, index = 0) => {
  const container = await findFileRowContainer(row);

  return (await findAllByText(container, name, { selector: '.file-row-name' }))
    .map(x => x.closest('.file-row'))
    .find(x => x.dataset.level === index.toString());
};

const clickOnLeftSidebarTab = async name => {
  const sidebar = await getLeftSidebar();

  const button = await findByLabelText(sidebar, name);

  button.click();
};

const fillInNewEntryModal = async path => {
  const input = await screen.findByTestId('ide-new-entry-file-name');
  fireEvent.change(input, { target: { value: path } });
  fireEvent.input(input, { target: { value: path } });

  const button = await screen.findByText('Create file');
  button.click();
};

const setEditorValue = async value => {
  const editor = await findMonacoEditor();
  const uri = editor.getAttribute('data-uri');

  window.monaco.editor.getModel(uri).setValue(value);
};

const clickRootAction = async name => {
  findByTitle(await findTreeActions(), name).click();
};

const clickFileAction = async (row, name) => {
  if (!row) {
    await clickRootAction(name);
    return;
  }

  fireEvent.mouseOver(row);

  const dropdown = row.querySelector('.ide-new-btn');
  dropdown.querySelector('button').click();
  getByText(dropdown, name).click();
};

const openFileRow = async row => {
  if (!row || isFileRowOpen(row)) {
    return;
  }

  row.click();
};

const traverseToPath = async (path, index = 0, row = null) => {
  if (!path) {
    return row;
  }

  const [name, ...restOfPath] = path.split('/');

  await openFileRow(row);

  const child = await findFileRow(name, row, index);

  return traverseToPath(restOfPath.join('/'), index + 1, child);
};

export const createNewFile = async (path, content = '') => {
  const parentPath = path
    .split('/')
    .slice(0, -1)
    .join('/');

  await clickFileAction(await traverseToPath(parentPath), 'New file');

  await fillInNewEntryModal(path);

  await setEditorValue(content);
};

export const deleteFile = async path => {
  await clickFileAction(await traverseToPath(path), 'Delete');
};

export const commitChanges = async () => {
  await clickOnLeftSidebarTab('Commit');
  (await screen.findByText('Commit…')).click();
  (await screen.findByLabelText(/^Commit to .+ branch/)).click();
  (await screen.findByText('Commit')).click();

  await screen.findByText('All changes are committed');
};
