import filterByKey from 'ee/vue_shared/security_reports/store/utils/filter_by_key';

const keyToFilterBy = 'fingerprint';

// eslint-disable-next-line no-restricted-globals
self.addEventListener('message', e => {
  const { data } = e;

  if (data === undefined) {
    return;
  }

  // eslint-disable-next-line no-restricted-globals
  self.postMessage({
    newIssues: filterByKey(data.parsedHeadIssues, data.parsedBaseIssues, keyToFilterBy),
    resolvedIssues: filterByKey(data.parsedBaseIssues, data.parsedHeadIssues, keyToFilterBy),
  });

  // eslint-disable-next-line no-restricted-globals
  self.close();
});
