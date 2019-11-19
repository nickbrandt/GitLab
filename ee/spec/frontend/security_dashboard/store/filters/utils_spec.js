import { hasValidSelection } from 'ee/security_dashboard/store/modules/filters/utils';

describe('filters module utils', () => {
  describe('hasValidSelection', () => {
    describe.each`
      selection         | options           | expected
      ${[]}             | ${[]}             | ${true}
      ${[]}             | ${['foo']}        | ${true}
      ${['foo']}        | ${['foo']}        | ${true}
      ${['foo']}        | ${['foo', 'bar']} | ${true}
      ${['bar', 'foo']} | ${['foo', 'bar']} | ${true}
      ${['foo']}        | ${[]}             | ${false}
      ${['foo']}        | ${['bar']}        | ${false}
      ${['foo', 'bar']} | ${['foo']}        | ${false}
    `('given selection $selection and options $options', ({ selection, options, expected }) => {
      let filter;
      beforeEach(() => {
        filter = {
          selection,
          options: options.map(id => ({ id })),
        };
      });

      it(`return ${expected}`, () => {
        expect(hasValidSelection(filter)).toBe(expected);
      });
    });
  });
});
