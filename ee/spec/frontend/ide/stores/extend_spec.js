import extendStore from 'ee/ide/stores/extend';
import terminalPlugin from 'ee/ide/stores/plugins/terminal';

jest.mock('ee/ide/stores/plugins/terminal', () => {
  const plugin = jest.fn();
  return jest.fn(() => plugin);
});

describe('ee/ide/stores/extend', () => {
  let store;
  let el;

  beforeEach(() => {
    store = {};
    el = {};

    extendStore(store, el);
  });

  it('creates terminal plugin', () => {
    expect(terminalPlugin).toHaveBeenCalledWith(el);
  });

  it('calls terminal plugin', () => {
    expect(terminalPlugin()).toHaveBeenCalledWith(store);
  });
});
