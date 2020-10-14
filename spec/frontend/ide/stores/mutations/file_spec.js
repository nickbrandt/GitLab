import mutations from '~/ide/stores/mutations/file';
import { createStore } from '~/ide/stores';
import { FILE_VIEW_MODE_PREVIEW } from '~/ide/constants';
import { file } from '../../helpers';

describe('IDE store file mutations', () => {
  let localState;
  let localStore;
  let localFile;

  beforeEach(() => {
    localStore = createStore();
    localState = localStore.state;
    localFile = { ...file('file'), type: 'blob', content: 'original' };

    localState.entries[localFile.path] = localFile;
  });

  describe('SET_FILE_ACTIVE', () => {
    it('sets the file active', () => {
      mutations.SET_FILE_ACTIVE(localState, {
        path: localFile.path,
        active: true,
      });

      expect(localFile.active).toBeTruthy();
    });

    it('sets pending tab as not active', () => {
      localState.openFiles.push({ ...localFile, pending: true, active: true });

      mutations.SET_FILE_ACTIVE(localState, {
        path: localFile.path,
        active: true,
      });

      expect(localState.openFiles[0].active).toBe(false);
    });
  });

  describe('TOGGLE_FILE_OPEN', () => {
    it('adds into opened files', () => {
      mutations.TOGGLE_FILE_OPEN(localState, localFile.path);

      expect(localFile.opened).toBeTruthy();
      expect(localState.openFiles.length).toBe(1);
    });

    describe('if already open', () => {
      it('removes from opened files', () => {
        mutations.TOGGLE_FILE_OPEN(localState, localFile.path);
        mutations.TOGGLE_FILE_OPEN(localState, localFile.path);

        expect(localFile.opened).toBeFalsy();
        expect(localState.openFiles.length).toBe(0);
      });
    });

    it.each`
      entry                                | loading
      ${{ opened: false }}                 | ${true}
      ${{ opened: false, tempFile: true }} | ${false}
      ${{ opened: true }}                  | ${false}
    `('for state: $entry, sets loading=$loading', ({ entry, loading }) => {
      Object.assign(localFile, entry);

      mutations.TOGGLE_FILE_OPEN(localState, localFile.path);

      expect(localFile.loading).toBe(loading);
    });
  });

  describe('SET_FILE_DATA', () => {
    it('sets extra file data', () => {
      mutations.SET_FILE_DATA(localState, {
        data: {
          raw_path: 'raw',
        },
        file: localFile,
      });

      expect(localFile.rawPath).toBe('raw');
      expect(localFile.raw).toBeNull();
      expect(localFile.baseRaw).toBeNull();
    });

    it('sets extra file data to all arrays concerned', () => {
      localState.stagedFiles = [localFile];
      localState.changedFiles = [localFile];
      localState.openFiles = [localFile];

      const rawPath = 'foo/bar/blah.md';

      mutations.SET_FILE_DATA(localState, {
        data: {
          raw_path: rawPath,
        },
        file: localFile,
      });

      expect(localState.stagedFiles[0].rawPath).toEqual(rawPath);
      expect(localState.changedFiles[0].rawPath).toEqual(rawPath);
      expect(localState.openFiles[0].rawPath).toEqual(rawPath);
      expect(localFile.rawPath).toEqual(rawPath);
    });

    it('does not mutate certain props on the file', () => {
      const path = 'New Path';
      const name = 'New Name';
      localFile.path = path;
      localFile.name = name;

      localState.stagedFiles = [localFile];
      localState.changedFiles = [localFile];
      localState.openFiles = [localFile];

      mutations.SET_FILE_DATA(localState, {
        data: {
          path: 'Old Path',
          name: 'Old Name',
          raw: 'Old Raw',
          base_raw: 'Old Base Raw',
        },
        file: localFile,
      });

      [
        localState.stagedFiles[0],
        localState.changedFiles[0],
        localState.openFiles[0],
        localFile,
      ].forEach(f => {
        expect(f).toEqual(
          expect.objectContaining({
            path,
            name,
            raw: null,
            baseRaw: null,
          }),
        );
      });
    });
  });

  describe('SET_FILE_RAW_DATA', () => {
    const callMutationForFile = f => {
      mutations.SET_FILE_RAW_DATA(localState, {
        file: f,
        raw: 'testing',
      });
    };

    it('sets raw data', () => {
      callMutationForFile(localFile);

      expect(localFile.raw).toBe('testing');
    });

    it('sets raw data to stagedFile if file was deleted and readded', () => {
      localState.stagedFiles = [{ ...localFile, deleted: true }];
      localFile.tempFile = true;

      callMutationForFile(localFile);

      expect(localFile.raw).toBeFalsy();
      expect(localState.stagedFiles[0].raw).toBe('testing');
    });

    it("sets raw data to a file's content if tempFile is empty", () => {
      localFile.tempFile = true;
      localFile.content = '';

      callMutationForFile(localFile);

      expect(localFile.raw).toBeFalsy();
      expect(localFile.content).toBe('testing');
    });

    it('adds raw data to open pending file', () => {
      localState.openFiles.push({ ...localFile, pending: true });

      callMutationForFile(localFile);

      expect(localState.openFiles[0].raw).toBe('testing');
    });

    it('sets raw to content of a renamed tempFile', () => {
      localFile.tempFile = true;
      localFile.prevPath = 'old_path';
      localState.openFiles.push({ ...localFile, pending: true });

      callMutationForFile(localFile);

      expect(localState.openFiles[0].raw).not.toBe('testing');
      expect(localState.openFiles[0].content).toBe('testing');
    });

    it('adds raw data to a staged deleted file if unstaged change has a tempFile of the same name', () => {
      localFile.tempFile = true;
      localState.openFiles.push({ ...localFile, pending: true });
      localState.stagedFiles = [{ ...localFile, deleted: true }];

      callMutationForFile(localFile);

      expect(localFile.raw).toBeFalsy();
      expect(localState.stagedFiles[0].raw).toBe('testing');
    });
  });

  describe('SET_FILE_BASE_RAW_DATA', () => {
    it('sets raw data from base branch', () => {
      mutations.SET_FILE_BASE_RAW_DATA(localState, {
        file: localFile,
        baseRaw: 'testing',
      });

      expect(localFile.baseRaw).toBe('testing');
    });
  });

  describe('UPDATE_FILE_CONTENT', () => {
    beforeEach(() => {
      localFile.raw = 'test';
    });

    it('sets content', () => {
      mutations.UPDATE_FILE_CONTENT(localState, {
        path: localFile.path,
        content: 'test',
      });

      expect(localFile.content).toBe('test');
    });

    it('sets changed if content does not match raw', () => {
      mutations.UPDATE_FILE_CONTENT(localState, {
        path: localFile.path,
        content: 'testing',
      });

      expect(localFile.content).toBe('testing');
      expect(localFile.changed).toBeTruthy();
    });

    it('sets changed if file is a temp file', () => {
      localFile.tempFile = true;

      mutations.UPDATE_FILE_CONTENT(localState, {
        path: localFile.path,
        content: '',
      });

      expect(localFile.changed).toBeTruthy();
    });
  });

  describe('SET_FILE_MERGE_REQUEST_CHANGE', () => {
    it('sets file mr change', () => {
      mutations.SET_FILE_MERGE_REQUEST_CHANGE(localState, {
        file: localFile,
        mrChange: {
          diff: 'ABC',
        },
      });

      expect(localFile.mrChange.diff).toBe('ABC');
    });

    it('has diffMode replaced by default', () => {
      mutations.SET_FILE_MERGE_REQUEST_CHANGE(localState, {
        file: localFile,
        mrChange: {
          diff: 'ABC',
        },
      });

      expect(localFile.mrChange.diffMode).toBe('replaced');
    });

    it('has diffMode new', () => {
      mutations.SET_FILE_MERGE_REQUEST_CHANGE(localState, {
        file: localFile,
        mrChange: {
          diff: 'ABC',
          new_file: true,
        },
      });

      expect(localFile.mrChange.diffMode).toBe('new');
    });

    it('has diffMode deleted', () => {
      mutations.SET_FILE_MERGE_REQUEST_CHANGE(localState, {
        file: localFile,
        mrChange: {
          diff: 'ABC',
          deleted_file: true,
        },
      });

      expect(localFile.mrChange.diffMode).toBe('deleted');
    });

    it('has diffMode renamed', () => {
      mutations.SET_FILE_MERGE_REQUEST_CHANGE(localState, {
        file: localFile,
        mrChange: {
          diff: 'ABC',
          renamed_file: true,
        },
      });

      expect(localFile.mrChange.diffMode).toBe('renamed');
    });
  });

  describe('DISCARD_FILE_CHANGES', () => {
    beforeEach(() => {
      localFile.content = 'test';
      localFile.changed = true;
      localState.currentProjectId = 'gitlab-ce';
      localState.currentBranchId = 'master';
      localState.trees['gitlab-ce/master'] = {
        tree: [],
      };
    });

    it('resets content and changed', () => {
      mutations.DISCARD_FILE_CHANGES(localState, localFile.path);

      expect(localFile.content).toBe('');
      expect(localFile.changed).toBeFalsy();
    });

    it('adds to root tree if deleted', () => {
      localFile.deleted = true;

      mutations.DISCARD_FILE_CHANGES(localState, localFile.path);

      expect(localState.trees['gitlab-ce/master'].tree).toEqual([{ ...localFile, deleted: false }]);
    });

    it('adds to parent tree if deleted', () => {
      localFile.deleted = true;
      localFile.parentPath = 'parentPath';
      localState.entries.parentPath = {
        tree: [],
      };

      mutations.DISCARD_FILE_CHANGES(localState, localFile.path);

      expect(localState.entries.parentPath.tree).toEqual([{ ...localFile, deleted: false }]);
    });
  });

  describe('ADD_FILE_TO_CHANGED', () => {
    it('adds file into changed files array', () => {
      mutations.ADD_FILE_TO_CHANGED(localState, localFile.path);

      expect(localState.changedFiles.length).toBe(1);
    });
  });

  describe('REMOVE_FILE_FROM_CHANGED', () => {
    it('removes files from changed files array', () => {
      localState.changedFiles.push(localFile);

      mutations.REMOVE_FILE_FROM_CHANGED(localState, localFile.path);

      expect(localState.changedFiles.length).toBe(0);
    });
  });

  describe('TOGGLE_FILE_CHANGED', () => {
    it('updates file changed status', () => {
      mutations.TOGGLE_FILE_CHANGED(localState, {
        file: localFile,
        changed: true,
      });

      expect(localFile.changed).toBeTruthy();
    });
  });

  describe('SET_FILE_VIEWMODE', () => {
    it('updates file view mode', () => {
      mutations.SET_FILE_VIEWMODE(localState, {
        file: localFile,
        viewMode: FILE_VIEW_MODE_PREVIEW,
      });

      expect(localFile.viewMode).toBe(FILE_VIEW_MODE_PREVIEW);
    });
  });

  describe('ADD_PENDING_TAB', () => {
    beforeEach(() => {
      const f = { ...file('openFile'), path: 'openFile', active: true, opened: true };

      localState.entries[f.path] = f;
      localState.openFiles.push(f);
    });

    it('adds file into openFiles as pending', () => {
      mutations.ADD_PENDING_TAB(localState, {
        file: localFile,
      });

      expect(localState.openFiles.length).toBe(1);
      expect(localState.openFiles[0].pending).toBe(true);
      expect(localState.openFiles[0].key).toBe(`pending-${localFile.key}`);
    });

    it('only allows 1 open pending file', () => {
      const newFile = file('test');
      localState.entries[newFile.path] = newFile;

      mutations.ADD_PENDING_TAB(localState, {
        file: localFile,
      });

      expect(localState.openFiles.length).toBe(1);

      mutations.ADD_PENDING_TAB(localState, {
        file: file('test'),
      });

      expect(localState.openFiles.length).toBe(1);
      expect(localState.openFiles[0].name).toBe('test');
    });
  });

  describe('REMOVE_PENDING_TAB', () => {
    it('removes pending tab from openFiles', () => {
      localFile.key = 'testing';
      localState.openFiles.push(localFile);

      mutations.REMOVE_PENDING_TAB(localState, localFile);

      expect(localState.openFiles.length).toBe(0);
    });
  });
});
