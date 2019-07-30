import filterByKey from 'ee/vue_shared/security_reports/store/utils/filter_by_key';

const keyToFilterBy = 'fingerprint';

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
    newIssues: filterByKey(headIssues, baseIssues, keyToFilterBy),
    resolvedIssues: filterByKey(baseIssues, headIssues, keyToFilterBy),
  });

  // eslint-disable-next-line no-restricted-globals
  return self.close();
});
