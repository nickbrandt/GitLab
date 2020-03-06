import Editor from '~/editor/editor_lite';
import * as utils from '~/blob/utils';

const mockCreateInstance = jest.fn();
jest.mock('~/editor/editor_lite', () => {
  return jest.fn().mockImplementation(() => {
    return { createInstance: mockCreateInstance };
  });
});

describe('Blob utilities', () => {
  beforeEach(() => {
    Editor.mockClear();
  });

  describe('initEditorLite', () => {
    let editorEl;
    const blobPath = 'foo.txt';
    const blobContent = 'Foo bar';

    beforeEach(() => {
      setFixtures('<div id="editor"></div>');
      editorEl = document.getElementById('editor');
    });

    it('initializes the Editor Lite', () => {
      utils.initEditorLite({ el: editorEl });
      expect(Editor).toHaveBeenCalled();
    });

    it('creates the instance with the passed parameters', () => {
      utils.initEditorLite({ el: editorEl });
      expect(mockCreateInstance.mock.calls[0]).toEqual([
        {
          el: editorEl,
          blobPath: undefined,
          blobContent: undefined,
        },
      ]);

      utils.initEditorLite({ el: editorEl, blobPath, blobContent });
      expect(mockCreateInstance.mock.calls[1]).toEqual([
        {
          el: editorEl,
          blobPath,
          blobContent,
        },
      ]);
    });
  });
});
