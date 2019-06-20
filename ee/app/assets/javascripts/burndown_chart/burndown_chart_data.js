import dateFormat from 'dateformat';

export default class BurndownChartData {
  constructor(burndownEvents, startDate, dueDate) {
    this.dateFormatMask = 'yyyy-mm-dd';
    this.startDate = startDate;
    this.dueDate = dueDate;
    this.burndownEvents = this.processRawEvents(burndownEvents);

    // determine when to stop burndown chart
    const today = dateFormat(new Date(), this.dateFormatMask);
    this.endDate = today < this.dueDate ? today : this.dueDate;
  }

  generate() {
    let openIssuesCount = 0;
    let openIssuesWeight = 0;

    const chartData = [];

    for (
      let date = new Date(this.startDate);
      date <= new Date(this.endDate);
      date.setDate(date.getDate() + 1)
    ) {
      const dateString = dateFormat(date, this.dateFormatMask);

      const openedIssuesToday = this.filterAndSummarizeBurndownEvents(
        event =>
          event.created_at === dateString &&
          (event.action === 'created' || event.action === 'reopened'),
      );

      const closedIssuesToday = this.filterAndSummarizeBurndownEvents(
        event => event.created_at === dateString && event.action === 'closed',
      );

      openIssuesCount += openedIssuesToday.count - closedIssuesToday.count;
      openIssuesWeight += openedIssuesToday.weight - closedIssuesToday.weight;

      chartData.push([dateString, openIssuesCount, openIssuesWeight]);
    }

    return chartData;
  }

  // Process raw milestone events:
  // 1. Set event creation date to milestone start date if created before milestone start
  // 2. Convert event creation date to local timezone
  processRawEvents(events) {
    return events.map(event => ({
      ...event,
      created_at: dateFormat(
        new Date(event.created_at) < new Date(this.startDate) ? this.startDate : event.created_at,
        this.dateFormatMask,
      ),
    }));
  }

  filterAndSummarizeBurndownEvents(filter) {
    const issues = this.burndownEvents.filter(filter);

    return {
      count: issues.length,
      weight: issues.reduce((total, issue) => total + issue.weight, 0),
    };
  }
}
