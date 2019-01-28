import state from 'ee/feature_flags/store/modules/edit/state';
import mutations from 'ee/feature_flags/store/modules/edit/mutations';
import * as types from 'ee/feature_flags/store/modules/edit/mutation_types';

describe('Feature flags Edit Module Mutations', () => {
  let stateCopy;

  beforeEach(() => {
    stateCopy = state();
  });

  describe('SET_ENDPOINT', () => {
    it('should set endpoint', () => {
      mutations[types.SET_ENDPOINT](stateCopy, 'feature_flags.json');

      expect(stateCopy.endpoint).toEqual('feature_flags.json');
    });
  });

  describe('SET_PATH', () => {
    it('should set provided options', () => {
      mutations[types.SET_PATH](stateCopy, 'feature_flags');

      expect(stateCopy.path).toEqual('feature_flags');
    });
  });

  describe('REQUEST_FEATURE_FLAG', () => {
    it('should set isLoading to true', () => {
      mutations[types.REQUEST_FEATURE_FLAG](stateCopy);

      expect(stateCopy.isLoading).toEqual(true);
    });

    it('should set error to an empty array', () => {
      mutations[types.REQUEST_FEATURE_FLAG](stateCopy);

      expect(stateCopy.error).toEqual([]);
    });
  });

  describe('RECEIVE_FEATURE_FLAG_SUCCESS', () => {
    const data = {
      name: '*',
      description: 'All environments',
      scopes: [{ id: 1 }],
    };

    beforeEach(() => {
      mutations[types.RECEIVE_FEATURE_FLAG_SUCCESS](stateCopy, data);
    });

    it('should set isLoading to false', () => {
      expect(stateCopy.isLoading).toEqual(false);
    });

    it('should set hasError to false', () => {
      expect(stateCopy.hasError).toEqual(false);
    });

    it('should set name with the provided one', () => {
      expect(stateCopy.name).toEqual(data.name);
    });

    it('should set description with the provided one', () => {
      expect(stateCopy.description).toEqual(data.description);
    });

    it('should set scope with the provided one', () => {
      expect(stateCopy.scope).toEqual(data.scope);
    });
  });

  describe('RECEIVE_FEATURE_FLAG_ERROR', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_FEATURE_FLAG_ERROR](stateCopy);
    });

    it('should set isLoading to false', () => {
      expect(stateCopy.isLoading).toEqual(false);
    });

    it('should set hasError to true', () => {
      expect(stateCopy.hasError).toEqual(true);
    });
  });

  describe('REQUEST_UPDATE_FEATURE_FLAG', () => {
    beforeEach(() => {
      mutations[types.REQUEST_UPDATE_FEATURE_FLAG](stateCopy);
    });

    it('should set isSendingRequest to true', () => {
      expect(stateCopy.isSendingRequest).toEqual(true);
    });

    it('should set error to an empty array', () => {
      expect(stateCopy.error).toEqual([]);
    });
  });

  describe('RECEIVE_UPDATE_FEATURE_FLAG_SUCCESS', () => {
    it('should set isSendingRequest to false', () => {
      mutations[types.RECEIVE_UPDATE_FEATURE_FLAG_SUCCESS](stateCopy);

      expect(stateCopy.isSendingRequest).toEqual(false);
    });
  });

  describe('RECEIVE_UPDATE_FEATURE_FLAG_ERROR', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_UPDATE_FEATURE_FLAG_ERROR](stateCopy, {
        message: ['Name is required'],
      });
    });

    it('should set isSendingRequest to false', () => {
      expect(stateCopy.isSendingRequest).toEqual(false);
    });

    it('should set error to the given message', () => {
      expect(stateCopy.error).toEqual(['Name is required']);
    });
  });
});
