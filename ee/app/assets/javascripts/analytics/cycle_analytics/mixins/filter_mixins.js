export default {
  data() {
    return {
      dateOptions: [7, 30, 90],
      selectedGroup: null,
      selectedProjectIds: [],
      multiProjectSelect: true,
    };
  },
  methods: {
    renderSelectedGroup(selectedItemURL) {
      this.service = this.createCycleAnalyticsService(selectedItemURL);
      this.loadAnalyticsData();
    },
    setSelectedGroup(selectedGroup) {
      this.selectedGroup = selectedGroup;
      this.renderSelectedGroup(`/groups/${selectedGroup.path}/-/value_stream_analytics`);
    },
    setSelectedProjects(selectedProjects) {
      this.selectedProjectIds = selectedProjects.map(value => value.id);
      this.loadAnalyticsData();
    },
    setSelectedDate(days) {
      if (this.startDate !== days) {
        this.startDate = days;
        this.loadAnalyticsData();
      }
    },
    loadAnalyticsData() {
      this.fetchCycleAnalyticsData({
        startDate: this.startDate,
        projectIds: this.selectedProjectIds,
      });
    },
  },
};
