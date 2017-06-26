import _ from 'underscore';
import mock from './mock';
import { UPSTREAM, DOWNSTREAM } from '../constants';

export default class PipelineStore {
  constructor() {
    this.state = {};

    this.state.pipeline = {};
    this.state.graph = {};
    this.state.upstreams = [];
    this.state.downstreams = [];
  }

  storePipeline(pipeline = mock) {
    pipeline = mock;

    this.state.pipeline = pipeline;

    this.state.graph = pipeline.details.stages;

    // EE feature - has upstream and downstream pipelines
    if (pipeline.triggered) {
      pipeline.triggered.map(downstream => this.addDownstream(downstream));
    }

    if (pipeline.triggered_by) {
      this.addUpstream(pipeline.triggered_by);
    }
  }

  addUpstream(upstream = {}) {
    if (!_.findWhere(this.state.upstreams, { id: upstream.id })) {
      this.state.upstreams.push(Object.assign({}, upstream, { expanded: false }));
    }
  }

  updateUpstream(upstream) {
    // Update the entire array: https://vuejs.org/v2/guide/list.html#Replacing-an-Array
    const upstreamCopy = this.upstream;

    upstreamCopy.map((element) => {
      if (upstream.id === element.id) {
        return Object.assign({}, element, upstream);
      }
      return element;
    });

    debugger;

    this.upstream = upstreamCopy;
  }

  addDownstream(downstream = {}) {
    if (!_.findWhere(this.state.downstreams, { id: downstream.id })) {
      this.state.downstreams.push(Object.assign({}, downstream, { expanded: false }));
    }
  }

  expandPipeline({ type, id }) {
    if (type === UPSTREAM) {
      // Assuming that each upstream has an object with an upstream
      // Let's look for the one with the given id
      const newUpstream = _.findWhere(this.state.upstreams, { id, expdanded: false });
      // Update the status in order to not be possible to expand it more than once
      this.updateUpstream(Object.assign({}, newUpstream, { expanded: true }));
      // And add it as an new upstream
      this.addUpstream(newUpstream.triggered_by);
    }
  }
}
