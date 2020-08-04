import { isValidConfigurationEntity } from 'ee/security_configuration/sast/components/utils';
import { makeEntities } from './helpers';

describe('isValidConfigurationEntity', () => {
  const validEntities = makeEntities(3);

  const invalidEntities = [
    null,
    undefined,
    [],
    {},
    ...makeEntities(1, { field: undefined }),
    ...makeEntities(1, { type: undefined }),
    ...makeEntities(1, { description: undefined }),
    ...makeEntities(1, { label: undefined }),
    ...makeEntities(1, { value: undefined }),
    ...makeEntities(1, { defaultValue: undefined }),
  ];

  it.each(validEntities)('returns true for a valid entity', entity => {
    expect(isValidConfigurationEntity(entity)).toBe(true);
  });

  it.each(invalidEntities)('returns false for an invalid entity', invalidEntity => {
    expect(isValidConfigurationEntity(invalidEntity)).toBe(false);
  });
});
