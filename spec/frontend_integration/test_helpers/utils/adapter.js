export const createAdapterInstance = (adapter, sourceFn) => {
  const currentSource = sourceFn();

  Object.keys(currentSource)
    .filter(key => Object.hasOwnProperty.call(currentSource, key))
    .forEach(key => {
      Object.defineProperty(adapter, key, {
        get() {
          return sourceFn()[key];
        },
        set(val) {
          const source = sourceFn();
          source[key] = val;
        },
      });
    });
};

export const createAdapter = sourceFn => {
  let isCreated = false;
  const adapter = {};

  const initialize = () => {
    if (isCreated) {
      return;
    }

    isCreated = true;
    createAdapterInstance(adapter, sourceFn);
  };

  return {
    adapter,
    initialize,
  };
};
