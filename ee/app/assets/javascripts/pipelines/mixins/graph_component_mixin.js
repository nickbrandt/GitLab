import _ from 'underscore';

export default {
  props: {
    triggered: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    triggeredBy: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    triggeredByPipelines: {
      type: Array,
      required: false,
      default: () => [],
    },
    triggeredPipelines: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      triggeredTopIndex: 1,
    };
  },
  computed: {
    triggeredGraph() {
      return this.triggered && this.triggered.details && this.triggered.details.stages;
    },
    triggeredByGraph() {
      return this.triggeredBy && this.triggeredBy.details && this.triggeredBy.details.stages;
    },
    hasTriggered() {
      return this.triggeredPipelines.length > 0;
    },
    hasTriggeredBy() {
      return this.triggeredByPipelines.length > 0;
    },
    shouldRenderTriggeredPipeline() {
      return !this.isLoading && !_.isEmpty(this.triggered);
    },
    shouldRenderTriggeredByPipeline() {
      return !this.isLoading && !_.isEmpty(this.triggeredBy);
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
