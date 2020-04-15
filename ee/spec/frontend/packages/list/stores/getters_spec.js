import * as getters from 'ee/packages/list/stores/getters';
import { packageList } from '../../mock_data';

describe('Getters registry list store', () => {
  let state;

  const setState = ({ isGroupPage = false } = {}) => {
    state = {
      packages: packageList,
      config: {
        isGroupPage,
      },
    };
  };

  beforeEach(() => setState());

  afterEach(() => {
    state = null;
  });

  describe('getList', () => {
    it('returns a list of packages', () => {
      const result = getters.getList(state);

      expect(result).toHaveLength(packageList.length);
      expect(result[0].name).toBe('Test package');
    });

    it('adds projectPathName', () => {
      const result = getters.getList(state);

      expect(result[0].projectPathName).toMatchInlineSnapshot(`"foo / bar / baz"`);
    });
  });

  describe('getCommitLink', () => {
    it('returns a relative link when isGroupPage is false', () => {
      const link = getters.getCommitLink(state)(packageList[0]);

      expect(link).toContain('../commit');
    });

    describe('when isGroupPage is true', () => {
      beforeEach(() => setState({ isGroupPage: true }));

      it('returns an absolute link matching project path', () => {
        const mavenPackage = packageList[0];
        const link = getters.getCommitLink(state)(mavenPackage);

        expect(link).toContain(`/${mavenPackage.project_path}/commit`);
      });
    });
  });
});
