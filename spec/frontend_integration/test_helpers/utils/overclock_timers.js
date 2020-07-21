// eslint-disable-next-line import/prefer-default-export
export const useOverclockTimers = (boost = 50) => {
  if (boost <= 0) {
    throw new Error(`[overclock_timers] boost (${boost}) cannot be <= 0`);
  }

  let origSetTimeout;
  let origSetInterval;
  const newSetTimeout = (fn, msParam = 0) => {
    const ms = msParam > 0 ? Math.floor(msParam / boost) : msParam;

    return origSetTimeout(fn, ms);
  };
  const newSetInterval = (fn, msParam = 0) => {
    const ms = msParam > 0 ? Math.floor(msParam / boost) : msParam;

    return origSetInterval(fn, ms);
  };

  beforeEach(() => {
    origSetTimeout = global.setTimeout;
    origSetInterval = global.setInterval;

    global.setTimeout = newSetTimeout;
    global.setInterval = newSetInterval;
  });

  afterEach(() => {
    global.setTimeout = origSetTimeout;
    global.setInterval = origSetInterval;
  });
};
