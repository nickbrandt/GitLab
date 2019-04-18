export default {
  methods: {
    filterByWeight(weight) {
      if (!this.updateFilters) return;

      const issueWeight = encodeURIComponent(weight);
      const filter = `weight=${issueWeight}`;

      this.applyFilter(filter);
    },
  },
};
