import { parseBoolean } from '../../../lib/utils/common_utils';

export default (initialState = {}) => {
  return {
    enabled: parseBoolean(initialState.enabled),
    editable: parseBoolean(initialState.editable),
    multiple: parseBoolean(initialState.multiple_clusters),
    info: initialState.cluster_info,
   
   
  }
};
  