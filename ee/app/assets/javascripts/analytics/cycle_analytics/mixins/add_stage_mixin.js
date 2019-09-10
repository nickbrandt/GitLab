export default {
  data() {
    return {
      isCustomStageForm: false,
    };
  },
  methods: {
    showAddStageForm() {
      if (this.store) {
        this.store.deactivateAllStages();
      }
      this.isCustomStageForm = true;
    },
    hideAddStageForm() {
      this.isCustomStageForm = false;
    },
  },
};
