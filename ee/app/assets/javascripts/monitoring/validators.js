// Prop validator for alert information, expecting an object like the example below.
//
// {
//   '/root/autodevops-deploy/prometheus/alerts/16.json?environment_id=37': {
//     alert_path: "/root/autodevops-deploy/prometheus/alerts/16.json?environment_id=37",
//     metricKey: '1',
//     operator: ">",
//     query: "rate(http_requests_total[5m])[30m:1m]",
//     threshold: 0.002,
//     title: "Core Usage (Total)",
//   }
// }
export function alertsValidator(value) {
  return Object.keys(value).every(key => {
    const alert = value[key];
    return (
      alert.alert_path &&
      key === alert.alert_path &&
      alert.metricKey &&
      typeof alert.metricKey === 'string' &&
      alert.operator &&
      typeof alert.threshold === 'number'
    );
  });
}

// Prop validator for query information, expecting an array like the example below.
//
// [
//   {
//     metricKey: '16',
//     label: 'Total Cores'
//   },
//   {
//     metricKey: '17',
//     label: 'Sub-total Cores'
//   }
// ]
export function queriesValidator(value) {
  return value.every(query => query.metricKey && typeof query.metricKey === 'string' && query.label);
}
