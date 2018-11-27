import axios from '~/lib/utils/axios_utils';
import CePipelineService from '~/pipelines/services/pipeline_service';

export default class PipelineStore extends CePipelineService {
  static getUpstreamDownstream(endpoint) {
    return axios.get(`${endpoint}.json`);
  }
}
