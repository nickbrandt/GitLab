// eslint-disable-next-line import/prefer-default-export
export const hasHistory = ({ statistics: { history } }) =>
  Boolean(history.nominal.length || history.anomalous.length);
