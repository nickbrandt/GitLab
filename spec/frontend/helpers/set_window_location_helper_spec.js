import setWindowLocationHelper from './set_window_location_helper';

describe('setWindowLocationHelper', () => {
  const originalLocation = window.location;

  afterEach(() => {
    window.location = originalLocation;
  });

  it.each`
    locationProperty | value
    ${'hash'}        | ${'foo'}
    ${'host'}        | ${'gitlab.com'}
    ${'hostname'}    | ${'gitlab.com'}
    ${'href'}        | ${'https://gitlab.com/foo'}
    ${'origin'}      | ${'https://gitlab.com'}
    ${'origin'}      | ${'/foo'}
    ${'port'}        | ${'80'}
    ${'protocol'}    | ${'https:'}
  `('sets "window.location.$locationProperty" to be $value', ({ locationProperty, value }) => {
    expect(window.location[locationProperty]).not.toBe(value);

    setWindowLocationHelper({
      [locationProperty]: value,
    });

    expect(window.location[locationProperty]).toBe(value);
  });
});
