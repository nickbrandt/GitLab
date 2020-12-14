import { languages } from 'monaco-editor';
import EditorLite from '~/editor/editor_lite';
import EditorCiSchemaExtension from '~/editor/editor_ci_schema_ext';

describe('~/editor/editor_ci_config_ext', () => {
  const mockBlobPath = '.gitlab-ci.yml';
  let editor;
  let instance;
  let editorEl;

  beforeEach(() => {
    setFixtures('<div id="editor"></div>');
    editorEl = document.getElementById('editor');
    editor = new EditorLite();
    instance = editor.createInstance({
      el: editorEl,
      blobPath: mockBlobPath,
      blobContent: '',
    });
    instance.use(EditorCiSchemaExtension);
  });

  afterEach(() => {
    instance.dispose();
    editorEl.remove();
  });

  describe('registerCiSchema', () => {
    beforeEach(() => {
      jest.spyOn(languages.yaml.yamlDefaults, 'setDiagnosticsOptions');
    });

    describe('register validations options with monaco for yaml language', () => {
      it('with expected basic validation configuration', () => {
        instance.registerCiSchema({ projectNamespace: 'namespace1', projectPath: 'project1' });

        const expectedOptions = {
          validate: true,
          enableSchemaRequest: true,
          hover: true,
          completion: true,
        };

        expect(languages.yaml.yamlDefaults.setDiagnosticsOptions).toHaveBeenCalledWith(
          expect.objectContaining(expectedOptions),
        );
      });

      it.each`
        opts                                                                | expectedUri
        ${{}}                                                               | ${'/namespace1/project1/-/schema/master/.gitlab-ci.yml'}
        ${{ ref: 'REF' }}                                                   | ${'/namespace1/project1/-/schema/REF/.gitlab-ci.yml'}
        ${{ projectNamespace: 'namespace2', projectPath: 'other-project' }} | ${'/namespace2/other-project/-/schema/master/.gitlab-ci.yml'}
      `('with the expected schema for options "$opts"', ({ opts, expectedUri }) => {
        instance.registerCiSchema({
          projectNamespace: 'namespace1',
          projectPath: 'project1',
          ...opts,
        });

        const expectedOptions = expect.objectContaining({
          schemas: [
            {
              uri: expectedUri,
              fileMatch: [mockBlobPath],
            },
          ],
        });

        expect(languages.yaml.yamlDefaults.setDiagnosticsOptions).toHaveBeenCalledWith(
          expectedOptions,
        );
      });
    });
  });
});
