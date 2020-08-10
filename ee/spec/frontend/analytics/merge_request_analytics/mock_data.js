export const throughputChartData = {
  May: { count: 2, __typename: 'MergeRequestConnection' },
  Jun: { count: 4, __typename: 'MergeRequestConnection' },
  Jul: { count: 3, __typename: 'MergeRequestConnection' },
  __typename: 'Project',
};

export const expectedMonthData = [
  {
    year: 2020,
    month: 'May',
    mergedAfter: '2020-05-01',
    mergedBefore: '2020-06-01',
  },
  {
    year: 2020,
    month: 'Jun',
    mergedAfter: '2020-06-01',
    mergedBefore: '2020-07-01',
  },
  {
    year: 2020,
    month: 'Jul',
    mergedAfter: '2020-07-01',
    mergedBefore: '2020-08-01',
  },
];

export const throughputChartQuery = `query ($fullPath: ID!) {
  throughputChartData: project(fullPath: $fullPath) {
    May_2020: mergeRequests(mergedBefore: "2020-06-01", mergedAfter: "2020-05-01") {
      count
    }
    Jun_2020: mergeRequests(mergedBefore: "2020-07-01", mergedAfter: "2020-06-01") {
      count
    }
    Jul_2020: mergeRequests(mergedBefore: "2020-08-01", mergedAfter: "2020-07-01") {
      count
    }
  }
}
`;
