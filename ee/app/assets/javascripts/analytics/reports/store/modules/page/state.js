import { s__ } from '~/locale';

export default () => ({
  isLoading: false,

  configEndpoint: '',
  reportId: null,

  groupName: null,
  groupPath: null,

  config: {
    title: s__('GenericReports|Report'),
    chart: null,
  },
});
