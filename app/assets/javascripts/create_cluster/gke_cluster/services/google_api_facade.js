/* global gapi */

// eslint-disable-next-line import/prefer-default-export
export const fetchNetworks = params =>
  gapi.client.compute.networks.list(params).then(({ result }) => {
    const items = result.items || [];

    return items.map(({ name, id, selfLink }) => ({ name, value: { id, selfLink } }));
  });

export const fetchSubnetworks = ({ project, region, network }) =>
  gapi.client.compute.subnetworks
    .list({
      project,
      region,
      // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
      filter: `network eq ${network}`,
    })
    .then(({ result }) => {
      const items = result.items || [];

      return items.map(({ id: value, name }) => ({ name, value }));
    });
