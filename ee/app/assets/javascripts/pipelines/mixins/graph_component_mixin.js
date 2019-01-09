export default {
  data() {
    return {
      triggeredTopIndex: 1,
    };
  },
  computed: {
    hasTriggeredBy() {
      return this.pipeline.triggered_by && this.pipeline.triggered_by != null;
    },
    triggeredByPipelines() {
      return this.pipeline.triggered_by;
    },
    hasTriggered() {
      return this.pipeline.triggered && this.pipeline.triggered.length > 0;
    },
    triggeredPipelines() {
      return this.pipeline.triggered;
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
      this.triggeredTopIndex = clickedIndex;
      this.$emit('onClickTriggered', pipeline);
    },
  },
};
