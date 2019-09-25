import { s__, sprintf } from '~/locale';
import { LABEL_SEARCH_QUERY, ACCEPTING_MR_LABEL_TEXT, AVAILABLE_TOURS } from './constants';

const GUIDED_GITLAB_TOUR = [
  {
    forUrl: ({ projectFullPath }) => new RegExp(`${projectFullPath}$`, ''),
    getHelpContent: ({ projectName }) => [
      {
        text: sprintf(
          s__(
            'UserOnboardingTour|Welcome to the project overview of the %{emphasisStart}%{projectName}%{emphasisEnd} project. This is the project that we use to work on GitLab. At first, a project seems like a simple repository, but at GitLab, a project is so much more.%{lineBreak}%{lineBreak}You can create projects for hosting your codebase, use it as an issue tracker, collaborate on code, and continuously build, test, and deploy your app with built-in GitLab CI/CD.',
          ),
          {
            emphasisStart: '<strong>',
            emphasisEnd: '</strong>',
            lineBreak: '<br/>',
            projectName,
          },
          false,
        ),
        buttons: [{ text: s__('UserOnboardingTour|Got it'), btnClass: 'btn-primary' }],
      },
    ],
    actionPopover: {
      selector: '#js-onboarding-repo-link',
      text: sprintf(
        s__(
          "UserOnboardingTour|Let's take a closer look at the repository of this project. Click on %{emphasisStart}Repository%{emphasisEnd}.",
        ),
        {
          emphasisStart: '<strong>',
          emphasisEnd: '</strong>',
        },
        false,
      ),
    },
  },
  {
    forUrl: ({ projectFullPath }) => new RegExp(`${projectFullPath}/tree/master$`, ''),
    getHelpContent: ({ projectName }) => [
      {
        text: sprintf(
          s__(
            "UserOnboardingTour|This is the repository for the %{emphasisStart}%{projectName}%{emphasisEnd} project. All our code is stored here. Feel free to explore and take a closer look at folders and files.%{lineBreak}%{lineBreak}Above the file structure you can see the latest commit, who the author is and the status of the CI/CD pipeline.%{lineBreak}%{lineBreak}If you scroll down below the file structure, you'll find the Readme of this project. This is defined in the README.md file at the root of the repository.",
          ),
          {
            emphasisStart: '<strong>',
            emphasisEnd: '</strong>',
            lineBreak: '</br>',
            projectName,
          },
          false,
        ),
        buttons: [{ text: s__('UserOnboardingTour|Got it'), btnClass: 'btn-primary' }],
      },
    ],
    actionPopover: {
      selector: '#js-onboarding-commits-link',
      text: sprintf(
        s__(
          "UserOnboardingTour|Let's take a closer look at all the commits. Click on %{emphasisStart}Commits%{emphasisEnd}.",
        ),
        {
          emphasisStart: '<strong>',
          emphasisEnd: '</strong>',
        },
        false,
      ),
    },
  },
  {
    forUrl: ({ projectFullPath }) => new RegExp(`${projectFullPath}/commits/master$`, ''),
    getHelpContent: () => [
      {
        text: s__(
          'UserOnboardingTour|Commits are shown in chronological order and can be filtered by the commit message or by the branch.',
        ),
        buttons: [{ text: s__('UserOnboardingTour|Got it'), btnClass: 'btn-primary' }],
      },
    ],
    actionPopover: {
      selector: '.js-onboarding-commit-item',
      text: s__('UserOnboardingTour|Click to open the latest commit to see its details.'),
    },
  },
  {
    forUrl: ({ projectFullPath }) => new RegExp(`${projectFullPath}/commit/[a-z0-9]+$`, ''),
    getHelpContent: () => [
      {
        text: sprintf(
          s__(
            "UserOnboardingTour|Here you can see what changes were made with this commit, on what branch and if there's a related merge request. The status of the pipeline will also show up if CI/CD is set up.%{lineBreak}%{lineBreak}You can also comment on the lines of code that were changed and start a discussion with your colleagues!",
          ),
          {
            lineBreak: '</br>',
          },
          false,
        ),
        buttons: [{ text: s__('UserOnboardingTour|Got it'), btnClass: 'btn-primary' }],
      },
    ],
    actionPopover: {
      selector: '#js-onboarding-branches-link',
      text: sprintf(
        s__(
          "UserOnboardingTour|Alright, that's it for Commits. Let's take a look at the %{emphasisStart}Branches%{emphasisEnd}.",
        ),
        {
          emphasisStart: '<strong>',
          emphasisEnd: '</strong>',
        },
        false,
      ),
    },
  },
  {
    forUrl: ({ projectFullPath }) => new RegExp(`${projectFullPath}/-/branches$`, ''),
    getHelpContent: ({ projectName }) => [
      {
        text: sprintf(
          s__(
            "UserOnboardingTour|Here's an overview of branches in the %{emphasisStart}%{projectName}%{emphasisEnd} project. They're split into Active and Stale.%{lineBreak}%{lineBreak}From here, you can create a new merge request from a branch, or compare the branch to any other branch in the project. By default, it will compare it to the master branch.",
          ),
          {
            emphasisStart: '<strong>',
            emphasisEnd: '</strong>',
            lineBreak: '</br>',
            projectName,
          },
          false,
        ),
        buttons: [{ text: s__('UserOnboardingTour|Got it'), btnClass: 'btn-primary' }],
      },
    ],
    actionPopover: {
      selector: '.js-onboarding-compare-branches',
      text: sprintf(
        s__(
          'UserOnboardingTour|Click on one of the %{emphasisStart}Compare%{emphasisEnd} buttons to compare a branch to master.',
        ),
        {
          emphasisStart: '<strong>',
          emphasisEnd: '</strong>',
        },
        false,
      ),
    },
  },
  {
    forUrl: ({ projectFullPath }) =>
      new RegExp(`${projectFullPath}/compare/master\\.\\.\\..+$`, ''),
    getHelpContent: () => [
      {
        text: s__(
          "UserOnboardingTour|Here you can compare the changes of this branch to another one. Changes are divided by files so that it's easier to see what was changed where.",
        ),
        buttons: [{ text: s__('UserOnboardingTour|Got it'), btnClass: 'btn-primary' }],
      },
    ],
    actionPopover: {
      selector: '#js-onboarding-issues-link',
      text: sprintf(
        s__(
          "UserOnboardingTour|That's it for the Repository. Let's take a look at the %{emphasisStart}Issues%{emphasisEnd}.",
        ),
        {
          emphasisStart: '<strong>',
          emphasisEnd: '</strong>',
        },
        false,
      ),
    },
  },
  {
    forUrl: ({ projectFullPath }) => new RegExp(`${projectFullPath}/issues$`, ''),
    getHelpContent: ({ projectName }) => [
      {
        text: sprintf(
          s__(
            'UserOnboardingTour|Issues are great for communicating and keeping track of progress in GitLab. These are all issues that are open in the %{emphasisStart}%{projectName}%{emphasisEnd}.%{lineBreak}%{lineBreak}You can help us improve GitLab by contributing work to issues that are labeled <span class="badge color-label accept-mr-label">Accepting merge requests</span>.%{lineBreak}%{lineBreak}This list can be filtered by labels, milestones, assignees, authors... We\'ll show you how it looks when the list is filtered by a label.',
          ),
          {
            emphasisStart: '<strong>',
            emphasisEnd: '</strong>',
            lineBreak: '</br>',
            projectName,
          },
          false,
        ),
        buttons: [
          {
            text: s__('UserOnboardingTour|Ok, show me'),
            btnClass: 'btn-primary',
            // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
            redirectPath: `issues?${LABEL_SEARCH_QUERY}`,
          },
        ],
      },
    ],
    actionPopover: null,
  },
  {
    forUrl: ({ projectFullPath }) =>
      new RegExp(
        `${projectFullPath}/issues\\?scope=all&state=opened&label_name\\[\\]=${encodeURIComponent(
          ACCEPTING_MR_LABEL_TEXT,
        )}$`,
        '',
      ),
    getHelpContent: () => [
      {
        text: s__(
          "UserOnboardingTour|These are all the issues that are available for community contributions. Let's take a closer look at one of them.",
        ),
        buttons: [{ text: s__('UserOnboardingTour|Got it'), btnClass: 'btn-primary' }],
      },
    ],
    actionPopover: {
      selector: '.js-onboarding-issue-item',
      text: s__('UserOnboardingTour|Open one of the issues by clicking on its title.'),
    },
  },
  {
    forUrl: ({ projectFullPath }) => new RegExp(`${projectFullPath}/issues/[0-9]+$`, ''),
    getHelpContent: () => [
      {
        text: sprintf(
          s__(
            "UserOnboardingTour|There's a lot of information here but don't worry, we'll go through it.%{lineBreak}%{lineBreak}On the top you can see the status of the issue and when it was opened and by whom. Directly below it is the issue description and below that are other %{emphasisStart}related issues%{emphasisEnd} and %{emphasisStart}merge requests%{emphasisEnd} (if any). Then below that is the %{emphasisStart}discussion%{emphasisEnd}, that's where most of the communication happens.%{lineBreak}%{lineBreak}On the right, there's a sidebar where you can view/change the %{emphasisStart}assignee, milestone, due date, labels, weight%{emphasisEnd}, etc.",
          ),
          {
            emphasisStart: '<strong>',
            emphasisEnd: '</strong>',
            lineBreak: '</br>',
          },
          false,
        ),
        buttons: [{ text: s__('UserOnboardingTour|Got it'), btnClass: 'btn-primary' }],
      },
    ],
    actionPopover: {
      selector: '#js-onboarding-mr-link',
      text: sprintf(
        s__(
          "UserOnboardingTour|That's it for issues. Let'st take a look at %{emphasisStart}Merge Requests%{emphasisEnd}.",
        ),
        {
          emphasisStart: '<strong>',
          emphasisEnd: '</strong>',
        },
        false,
      ),
    },
  },
  {
    forUrl: ({ projectFullPath }) => new RegExp(`${projectFullPath}/merge_requests$`, ''),
    getHelpContent: () => [
      {
        text: s__(
          'UserOnboardingTour|This is an overview of all merge requests in this project. Similarly to the issues overview it can be filtered down by things like labels, milestones, authors, assignees, etc.',
        ),
        buttons: [{ text: s__('UserOnboardingTour|Got it'), btnClass: 'btn-primary' }],
      },
    ],
    actionPopover: {
      selector: '.js-onboarding-mr-item',
      text: s__(
        "UserOnboardingTour|Let's take a closer look at a merge request. Click on the title of one.",
      ),
    },
  },
  {
    forUrl: ({ projectFullPath }) => new RegExp(`${projectFullPath}/merge_requests/[0-9]+$`, ''),
    getHelpContent: () => [
      {
        text: sprintf(
          s__(
            "UserOnboardingTour|The structure of this page is very similar to issues. Status, description, discussion and the sidebar are all here.%{lineBreak}%{lineBreak}But take a look below the description and you'll notice that there's more information about the merge request, the CI/CD pipeline and the options for approving it.%{lineBreak}%{lineBreak}Alongside the discussion you can also see more information about commits in this merge request, the status of pipelines and review all changes that were made.",
          ),
          {
            lineBreak: '</br>',
          },
          false,
        ),
        buttons: [{ text: s__('UserOnboardingTour|Got it'), btnClass: 'btn-primary' }],
      },
    ],
    actionPopover: {
      selector: '#js-onboarding-pipelines-link',
      text: sprintf(
        s__(
          "UserOnboardingTour|That's it for merge requests. Now for the final part of this guided tour - the %{emphasisStart}CI/CD%{emphasisEnd}.",
        ),
        {
          emphasisStart: '<strong>',
          emphasisEnd: '</strong>',
        },
        false,
      ),
    },
  },
  {
    forUrl: ({ projectFullPath }) => new RegExp(`${projectFullPath}/pipelines$`, ''),
    getHelpContent: ({ projectName }) => [
      {
        text: sprintf(
          s__(
            "UserOnboardingTour|These are all the CI/CD pipelines we have for our %{emphasisStart}%{projectName}%{emphasisEnd} project.%{lineBreak}%{lineBreak}Here you can see the status of each pipeline, for what commit it's running for, its stages and the status for them.",
          ),
          {
            emphasisStart: '<strong>',
            emphasisEnd: '</strong>',
            lineBreak: '</br>',
            projectName,
          },
          false,
        ),
        buttons: [{ text: s__('UserOnboardingTour|Got it'), btnClass: 'btn-primary' }],
      },
    ],
    actionPopover: {
      selector: '.js-onboarding-pipeline-item',
      text: sprintf(
        s__(
          'UserOnboardingTour|Click on one of the %{emphasisStart}pipeline IDs%{emphasisEnd} to see the details of a pipeline.',
        ),
        {
          emphasisStart: '<strong>',
          emphasisEnd: '</strong>',
        },
        false,
      ),
    },
  },
  {
    forUrl: ({ projectFullPath }) => new RegExp(`${projectFullPath}/pipelines/[0-9]+$`, ''),
    getHelpContent: () => [
      {
        text: sprintf(
          s__(
            'UserOnboardingTour|Here you can see the breakdown of the pipelines: its stages and jobs in each of the stages and their status.%{lineBreak}%{lineBreak}Our CI/CD pipelines are quite complex, most of our users have fewer and simpler pipelines.',
          ),
          {
            lineBreak: '</br>',
          },
          false,
        ),
        buttons: [
          {
            text: s__('UserOnboardingTour|Got it'),
            btnClass: 'btn-primary',
            dismissPopover: false,
          },
        ],
      },
      {
        text: sprintf(
          s__(
            "UserOnboardingTour|%{emphasisStart}Well done!%{emphasisEnd}%{lineBreak}%{lineBreak}That's it for our guided tour, congratulations for making it all the way to the end!%{lineBreak}%{lineBreak}We hope this gave you a good overview of GitLab and how it can help you. We'll now show you how to create your own project and invite your colleagues.",
          ),
          {
            emphasisStart: '<strong>',
            emphasisEnd: '</strong>',
            lineBreak: '</br>',
          },
          false,
        ),
        buttons: [
          {
            text: s__("UserOnboardingTour|Ok, let's go"),
            btnClass: 'btn-primary',
            nextPart: AVAILABLE_TOURS.CREATE_PROJECT_TOUR,
          },
          {
            text: s__('UserOnboardingTour|No thanks'),
            btnClass: 'btn-secondary',
            showExitTourContent: true,
          },
        ],
      },
    ],
    actionPopover: null,
  },
];

const CREATE_PROJECT_TOUR = [
  {
    forUrl: ({ projectFullPath }) => new RegExp(`${projectFullPath}/pipelines/[0-9]+$`, ''),
    getHelpContent: null,
    actionPopover: {
      selector: '#js-onboarding-new-project-link',
      text: s__(
        'UserOnboardingTour|Take a look. Here\'s a nifty menu for quickly creating issues, merge requests, snippets, projects and groups. Click on it and select "New project" from the "GitLab" section to get started.',
      ),
      placement: 'bottom',
    },
  },
  {
    forUrl: () => new RegExp(`/projects/new\\?*.*$`, ''),
    getHelpContent: () => [
      {
        text: sprintf(
          s__(
            "UserOnboardingTour|Here you can create a project from scratch, start with a template or import a repository from other platforms. Whatever you choose, we'll guide you through the process.%{lineBreak}%{lineBreak}Fill in your new project information and click on %{emphasisStart}Create Project%{emphasisEnd} to progress to the next step.",
          ),
          {
            emphasisStart: '<strong>',
            emphasisEnd: '</strong>',
            lineBreak: '</br>',
          },
          false,
        ),
        buttons: null,
      },
    ],
    actionPopover: null,
  },
  {
    forUrl: ({ createdProjectPath }) => new RegExp(`${createdProjectPath}$`, ''),
    getHelpContent: () => [
      {
        text: sprintf(
          s__(
            'UserOnboardingTour|Sweet! Your project was created and is ready to be used.%{lineBreak}%{lineBreak}You can start adding files to the repository or clone it. One last thing we want to show you is how to invite your colleagues to your new project.',
          ),
          {
            lineBreak: '</br>',
          },
          false,
        ),
        buttons: [
          {
            text: s__("UserOnboardingTour|Ok, let's go"),
            btnClass: 'btn-primary',
            nextPart: AVAILABLE_TOURS.INVITE_COLLEAGUES_TOUR,
          },
          {
            text: s__('UserOnboardingTour|No thanks'),
            btnClass: 'btn-secondary',
            showExitTourContent: true,
          },
        ],
      },
    ],
    actionPopover: null,
  },
];

const INVITE_COLLEAGUES_TOUR = [
  {
    forUrl: ({ createdProjectPath }) => new RegExp(`${createdProjectPath}$`, ''),
    getHelpContent: null,
    actionPopover: {
      selector: '#js-onboarding-settings-link',
      text: sprintf(
        s__(
          'UserOnboardingTour|Adding other members to a project is done through Project Settings. Click on %{emphasisStart}Settings%{emphasisEnd}.',
        ),
        {
          emphasisStart: '<strong>',
          emphasisEnd: '</strong>',
        },
        false,
      ),
    },
  },
  {
    forUrl: ({ createdProjectPath }) => new RegExp(`${createdProjectPath}/edit$`, ''),
    getHelpContent: null,
    actionPopover: {
      selector: '#js-onboarding-settings-members-link',
      text: sprintf(
        s__('UserOnboardingTour|Awesome! Now click on %{emphasisStart}Members%{emphasisEnd}.'),
        {
          emphasisStart: '<strong>',
          emphasisEnd: '</strong>',
        },
        false,
      ),
    },
  },
  {
    forUrl: ({ createdProjectPath }) => new RegExp(`${createdProjectPath}/-/project_members$`, ''),
    getHelpContent: () => [
      {
        text: sprintf(
          s__(
            'UserOnboardingTour|Here you can see the current members of the project (just you at the moment) and invite new members.%{lineBreak}%{lineBreak}You can invite multiple members at once (existing GitLab users or invite by email) and you can also set their roles and permissions.%{lineBreak}%{lineBreak}Add a few members and click on %{emphasisStart}Add to project%{emphasisEnd} to complete this step.',
          ),
          {
            emphasisStart: '<strong>',
            emphasisEnd: '</strong>',
            lineBreak: '</br>',
          },
          false,
        ),
        buttons: [
          {
            text: s__('UserOnboardingTour|Got it'),
            btnClass: 'btn-primary',
            showExitTourContent: true,
          },
        ],
      },
    ],
    actionPopover: null,
  },
];

export default {
  [AVAILABLE_TOURS.GUIDED_GITLAB_TOUR]: GUIDED_GITLAB_TOUR,
  [AVAILABLE_TOURS.CREATE_PROJECT_TOUR]: CREATE_PROJECT_TOUR,
  [AVAILABLE_TOURS.INVITE_COLLEAGUES_TOUR]: INVITE_COLLEAGUES_TOUR,
};
