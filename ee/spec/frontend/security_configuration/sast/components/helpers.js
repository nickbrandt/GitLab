/**
 * Creates an array of objects matching the shape of a GraphQl
 * SastCiConfigurationEntity.
 *
 * @param {number} count - The number of entities to create.
 * @param {Object} [changes] - Object representing changes to apply to the
 *     generated entities.
 * @returns {Object[]}
 */
// eslint-disable-next-line import/prefer-default-export
export const makeEntities = (count, changes) =>
  [...Array(count).keys()].map(i => ({
    defaultValue: `defaultValue${i}`,
    description: `description${i}`,
    field: `field${i}`,
    label: `label${i}`,
    type: 'string',
    value: `defaultValue${i}`,
    ...changes,
  }));
