// eslint-disable-next-line import/prefer-default-export
export const buildQuery = (params, map) =>
  Object.keys(map).reduce((acc, key) => {
    if (key in params) {
      return Object.assign(acc, { [map[key]]: params[key] });
    }
    return acc;
  }, {});
