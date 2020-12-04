import { languages } from 'monaco-editor';
import EditorLite from '~/editor/editor_lite';
import EditorCiSchemaExtension from '~/editor/editor_ci_schema_ext';

describe('~/editor/editor_ci_config_ext', () => {
  let editor;
  let instance;
  let editorEl;

  beforeEach(() => {
    setFixtures('<div id="editor" data-editor-loading></div>');
    editorEl = document.getElementById('editor');
    editor = new EditorLite();
    instance = editor.createInstance({
      el: editorEl,
      blobPath: '',
      blobContent: '',
    });
    editor.use(EditorCiSchemaExtension);
  });

  afterEach(() => {
    instance.dispose();
    editorEl.remove();
  });

  describe('registerCiSchema', () => {
    beforeEach(() => {
      jest.spyOn(languages.json.jsonDefaults, 'setDiagnosticsOptions');
      jest.spyOn(languages.yaml.yamlDefaults, 'setDiagnosticsOptions');
    });

    describe('register validations options with monaco for both json and yaml', () => {
      it('with expected basic validation configuration', () => {
        instance.registerCiSchema({ projectPath: 'namespace/my-project' });

        const expectedOptions = {
          validate: true,
          enableSchemaRequest: true,
          hover: true,
          completion: true,
        };

        expect(languages.json.jsonDefaults.setDiagnosticsOptions).toHaveBeenCalledWith(
          expect.objectContaining(expectedOptions),
        );
        expect(languages.yaml.yamlDefaults.setDiagnosticsOptions).toHaveBeenCalledWith(
          expect.objectContaining(expectedOptions),
        );
      });

      it.each`
        opts                             | expectedFileMatch   | expectedUri
        ${{}}                            | ${'.gitlab-ci.yml'} | ${'/namespace/my-project/-/schema/master/.gitlab-ci.yml'}
        ${{ ref: 'REF' }}                | ${'.gitlab-ci.yml'} | ${'/namespace/my-project/-/schema/REF/.gitlab-ci.yml'}
        ${{ fileName: 'custom-ci.yml' }} | ${'custom-ci.yml'}  | ${'/namespace/my-project/-/schema/master/.gitlab-ci.yml'}
      `(
        'with the expected schema for options "$opts"',
        ({ opts, expectedUri, expectedFileMatch }) => {
          instance.registerCiSchema({
            projectPath: 'namespace/my-project',
            ...opts,
          });

          const expectedOptions = expect.objectContaining({
            schemas: [
              {
                uri: expectedUri,
                fileMatch: [expectedFileMatch],
              },
            ],
          });

          expect(languages.json.jsonDefaults.setDiagnosticsOptions).toHaveBeenCalledWith(
            expectedOptions,
          );
          expect(languages.yaml.yamlDefaults.setDiagnosticsOptions).toHaveBeenCalledWith(
            expectedOptions,
          );
        },
      );
    });
  });
});
