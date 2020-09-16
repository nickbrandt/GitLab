export class StartupMock {
  constructor({ callPath, responseData, fetchSuccess = true }) {
    this.callPath = callPath;

    const response = {
      json: () => Promise.resolve(responseData),
    };

    window.gl.startup_calls = {
      [callPath]: {
        fetchCall: fetchSuccess ? Promise.resolve(response) : Promise.reject(),
      },
    };
  }

  restore() {
    delete window.gl.startup_calls[this.callPath];
  }
}
