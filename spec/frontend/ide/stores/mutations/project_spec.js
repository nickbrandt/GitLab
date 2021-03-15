import mutations from '~/ide/stores/mutations/project';
import state from '~/ide/stores/state';

describe('Multi-file store branch mutations', () => {
  let localState;
  const nonExistentProj = 'nonexistent';

  beforeEach(() => {
    localState = state();
    localState.projects = { abcproject: { empty_repo: true } };
  });

  describe('TOGGLE_EMPTY_STATE', () => {
    it('sets empty_repo for project to passed value', () => {
      mutations.TOGGLE_EMPTY_STATE(localState, { projectPath: 'abcproject', value: false });

      expect(localState.projects.abcproject.empty_repo).toBe(false);

      mutations.TOGGLE_EMPTY_STATE(localState, { projectPath: 'abcproject', value: true });

      expect(localState.projects.abcproject.empty_repo).toBe(true);
    });
  });

  describe('UPDATE_PROJECT', () => {
    it.each`
      desc                                                  | projectPath        | props
      ${'extends existing project with the passed props'}   | ${'abcproject'}    | ${{ foo1: 'bar' }}
      ${'overrides existing props on the exsiting project'} | ${'abcproject'}    | ${{ empty_repo: false }}
      ${'does nothing if the project does not exist'}       | ${nonExistentProj} | ${{ foo2: 'bar' }}
      ${'does nothing if project is not passed'}            | ${undefined}       | ${{ foo3: 'bar' }}
      ${'does nothing if the props are not passed'}         | ${'abcproject'}    | ${undefined}
      ${'does nothing if the props are empty'}              | ${'abcproject'}    | ${{}}
    `('$desc', ({ projectPath, props } = {}) => {
      const origProject = localState.projects[projectPath];

      mutations.UPDATE_PROJECT(localState, { projectPath, props });

      if (!projectPath || projectPath === nonExistentProj || !props || !Object.keys(props).length) {
        expect(localState.projects[projectPath]).toBe(origProject);
      } else {
        const expectedProps = Object.keys(props);
        expectedProps.forEach((prop) => {
          expect(localState.projects[projectPath][prop]).toBe(props[prop]);
        });
      }
    });
  });
});
