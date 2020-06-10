import * as getters from 'ee/geo_replicable/store/getters';
import createState from 'ee/geo_replicable/store/state';

describe('GeoReplicable Store Getters', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe('replicableTypeName', () => {
    it('handles a single word replicable type', () => {
      state.replicableType = 'designs';

      expect(getters.replicableTypeName(state)).toBe('designs');
    });

    it('handles a multi-word replicable type', () => {
      state.replicableType = 'package_files';

      expect(getters.replicableTypeName(state)).toBe('package files');
    });
  });
});
