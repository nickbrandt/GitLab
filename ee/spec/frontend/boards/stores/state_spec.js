import createState from 'ee/boards/stores/state';
import createStateCE from '~/boards/stores/state';

describe('createState', () => {
  it('is a function', () => {
    expect(createState).toEqual(expect.any(Function));
  });

  it('returns an object', () => {
    expect(createState()).toEqual(expect.any(Object));
  });

  it('contains the CE state', () => {
    expect(createState()).toEqual(expect.objectContaining(createStateCE()));
  });
});
