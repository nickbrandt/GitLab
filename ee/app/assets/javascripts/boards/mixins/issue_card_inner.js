import _ from 'underscore';

export default {
  computed: {
    validIssueWeight() {
      if (this.issue && _.isNumber(this.issue.weight)) {
        return this.issue.weight >= 0;
      }

      return false;
    },
  },
  methods: {
    filterByWeight(weight) {
      if (!this.updateFilters) return;

      const issueWeight = encodeURIComponent(weight);
      /* eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings */
      const filter = `weight=${issueWeight}`;

      this.applyFilter(filter);
    },
  },
};
