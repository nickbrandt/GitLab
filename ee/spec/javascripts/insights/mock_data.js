export const chartInfo = {
  title: 'Bugs Per Team',
  type: 'bar',
  query: {
    name: 'filter_issues_by_label_category',
    filter_label: 'bug',
    category_labels: ['Plan', 'Create', 'Manage'],
  },
};

export const chartData = {
  labels: ['January'],
  datasets: [
    {
      label: 'Dataset 1',
      fill: true,
      backgroundColor: ['rgba(255, 99, 132)'],
      data: [1],
    },
    {
      label: 'Dataset 2',
      fill: true,
      backgroundColor: ['rgba(54, 162, 235)'],
      data: [2],
    },
  ],
};

export const pageInfo = {
  title: 'Title',
  charts: [chartInfo],
};

export const pageInfoNoCharts = {
  page: {
    title: 'Page No Charts',
  },
};

export const configData = {
  example: pageInfo,
  invalid: {
    key: 'key',
  },
};
