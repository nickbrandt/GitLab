export const mockTourData = {
  1: [
    {
      forUrl: ({ projectFullPath }) => new RegExp(`${projectFullPath}/foo$`, ''),
      getHelpContent: () => [
        {
          text: 'foo',
          buttons: [{ text: 'button', btnClass: 'btn-primary' }],
        },
        {
          text: 'next content item',
          buttons: [{ text: 'button', btnClass: 'btn-primary' }],
        },
      ],
      actionPopover: {
        selector: '.popup-trigger',
        text: 'foo',
        placement: 'top',
      },
    },
    {
      forUrl: ({ projectFullPath }) => new RegExp(`${projectFullPath}/foo/bar$`, ''),
      getHelpContent: ({ projectName }) => [
        {
          text: `This is the ${projectName}`,
          buttons: [{ text: 'button', btnClass: 'btn-primary' }],
        },
      ],
      actionPopover: {
        selector: '',
        text: 'bar',
      },
    },
    {
      forUrl: ({ projectFullPath }) => new RegExp(`${projectFullPath}/xyz`, ''),
      getHelpContent: null,
      actionPopover: {
        selector: null,
        text: 'foo',
        placement: 'top',
      },
    },
  ],
};

export const mockData = {
  url: 'http://gitlab-org/gitlab-test/foo',
  projectFullPath: 'http://gitlab-org/gitlab-test',
  projectName: 'Mock Project',
  tourData: mockTourData,
  tourKey: 1,
  helpContentIndex: 0,
  lastStepIndex: -1,
  createdProjectPath: '',
};
