import filterByKey from '../store/utils/filter_by_key';

const KEY_TO_FILTER_BY = 'fingerprint';

// eslint-disable-next-line no-restricted-globals
self.addEventListener('message', e => {
  const { data } = e;

  if (data === undefined) {
    return null;
  }

  const { headIssues, baseIssues } = data;

  if (!headIssues || !baseIssues) {
    // eslint-disable-next-line no-restricted-globals
    return self.postMessage({});
  }

  // eslint-disable-next-line no-restricted-globals
  self.postMessage({
    newIssues: filterByKey(headIssues, baseIssues, KEY_TO_FILTER_BY),
    resolvedIssues: filterByKey(baseIssues, headIssues, KEY_TO_FILTER_BY),
  });

  // eslint-disable-next-line no-restricted-globals
  return self.close();
});
