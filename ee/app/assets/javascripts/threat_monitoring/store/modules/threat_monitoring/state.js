import { DEFAULT_TIME_WINDOW } from '../../../constants';

export default () => ({
  environmentsEndpoint: '',
  environments: [],
  isLoadingEnvironments: false,
  errorLoadingEnvironments: false,
  currentEnvironmentId: -1,
  currentTimeWindow: DEFAULT_TIME_WINDOW,
});
