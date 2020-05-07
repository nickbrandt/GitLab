import setWindowLocationHelper from './set_window_location_helper';

describe('setWindowLocationHelper', () => {
  const originalLocation = window.location;

  afterEach(() => {
    window.location = originalLocation;
  });

  it.each`
    property      | value
    ${'hash'}     | ${'foo'}
    ${'host'}     | ${'gitlab.com'}
    ${'hostname'} | ${'gitlab.com'}
    ${'href'}     | ${'https://gitlab.com/foo'}
    ${'origin'}   | ${'https://gitlab.com'}
    ${'origin'}   | ${'/foo'}
    ${'port'}     | ${'80'}
    ${'protocol'} | ${'https:'}
  `('sets "window.location.$property" to be $value', ({ property, value }) => {
    expect(window.location).toBe(originalLocation);

    setWindowLocationHelper({
      [property]: value,
    });

    expect(window.location[property]).toBe(value);
  });
});
