import _ from 'underscore';
import { parseFeatureFlagsParams, internalKeyID } from 'ee/feature_flags/store/modules/helpers';

describe('feature flags helpers spec', () => {
  describe('parseFeatureFlagsParams', () => {
    describe('with internalKeyId', () => {
      it('removes id', () => {
        const scopes = [
          {
            active: true,
            created_at: '2019-01-17T17:22:07.625Z',
            environment_scope: '*',
            id: 2,
            updated_at: '2019-01-17T17:22:07.625Z',
          },
          {
            active: true,
            created_at: '2019-03-11T11:18:42.709Z',
            environment_scope: 'review',
            id: 29,
            updated_at: '2019-03-11T11:18:42.709Z',
          },
          {
            active: true,
            created_at: '2019-03-11T11:18:42.709Z',
            environment_scope: 'review',
            id: _.uniqueId(internalKeyID),
            updated_at: '2019-03-11T11:18:42.709Z',
          },
        ];

        const parsedScopes = parseFeatureFlagsParams({
          name: 'review',
          scopes,
          description: 'feature flag',
        });

        expect(parsedScopes.operations_feature_flag.scopes_attributes[2].id).toEqual(undefined);
      });
    });
  });
});
