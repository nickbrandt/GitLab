// todo filipa: move this to the ee graph component
import _ from 'underscore';

export default {
  data() {
    return {
      triggeredTopIndex: 1,
    };
  },
  computed: {
    hasTriggeredBy() {
      return (
        this.type !== 'downstream' &&
        this.pipeline.triggered_by &&
        this.pipeline.triggered_by != null
      );
    },
    triggeredByPipelines() {
      return this.pipeline.triggered_by;
    },
    hasTriggered() {
      return (
        this.type !== 'upstream' && this.pipeline.triggered && this.pipeline.triggered.length > 0
      );
    },
    triggeredPipelines() {
      return this.pipeline.triggered;
    },
    expandedTriggeredBy() {
      return (
        this.pipeline.triggered_by &&
        _.isArray(this.pipeline.triggered_by) &&
        this.pipeline.triggered_by.find(el => el.isExpanded)
      );
    },
    expandedTriggered() {
      return this.pipeline.triggered && this.pipeline.triggered.find(el => el.isExpanded);
    },

    /**
     * Calculates the margin top of the clicked downstream pipeline by
     * adding the height of each linked pipeline and the margin
     */
    marginTop() {
      return `${this.triggeredTopIndex * 52}px`;
    },
  },
  methods: {
    // TODO FILIPA: REMOVE THIS
    refreshTriggeredPipelineGraph() {
      this.$emit('refreshTriggeredPipelineGraph');
    },
    refreshTriggeredByPipelineGraph() {
      this.$emit('refreshTriggeredByPipelineGraph');
    },
    handleClickedDownstream(pipeline, clickedIndex) {
      //filipa: figure out the clickIndex thing
      this.triggeredTopIndex = clickedIndex;
      this.$emit('onClickTriggered', this.pipeline, pipeline);
    },
  },
};
