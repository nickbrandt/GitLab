import eventHub from '~/environments/event_hub';

export default {
  computed: {
    deployIconName() {
      return this.model.isDeployBoardVisible ? 'chevron-down' : 'chevron-right';
    },
    shouldRenderDeployBoard() {
      return this.model.hasDeployBoard;
    },
  },
  methods: {
    toggleDeployBoard() {
      eventHub.$emit('toggleDeployBoard', this.model);
    },
  },
};
