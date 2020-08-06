import {
  isValidConfigurationEntity,
  extractSastConfigurationEntities,
} from 'ee/security_configuration/sast/components/utils';
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

describe('extractSastConfigurationEntities', () => {
  describe.each`
    context                    | response
    ${'which is empty'}        | ${{}}
    ${'with no project'}       | ${{ project: null }}
    ${'with no configuration'} | ${{ project: {} }}
  `('given a response $context', ({ response }) => {
    it('returns an empty array', () => {
      expect(extractSastConfigurationEntities(response)).toEqual([]);
    });
  });

  describe('given a valid response', () => {
    it('returns an array of entities from the global and pipeline sections', () => {
      const globalEntities = makeEntities(3, { description: 'global' });
      const pipelineEntities = makeEntities(3, { description: 'pipeline' });

      const response = {
        project: {
          sastCiConfiguration: {
            global: { nodes: globalEntities },
            pipeline: { nodes: pipelineEntities },
          },
        },
      };

      expect(extractSastConfigurationEntities(response)).toEqual([
        ...globalEntities,
        ...pipelineEntities,
      ]);
    });
  });
});
