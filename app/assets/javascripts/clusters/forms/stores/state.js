<<<<<<< HEAD
import { parseBoolean } from '../../../lib/utils/common_utils';

export default (initialState = {}) => {
  return {
    enabled: parseBoolean(initialState.enabled),
    editable: parseBoolean(initialState.editable),
  }
};
=======
export default (initialState = {}) => ({
    clusterEnabled: '',
    clusterDomain: '',
    clusterEnvironmentScope: '',
  });
>>>>>>> b224cc6b3333a8b554fc8c6025566be091ffe116
  