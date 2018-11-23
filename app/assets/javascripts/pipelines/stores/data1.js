export default {
  id: 37691949,
  user: {
    id: 1212235,
    name: 'Winnie Hellmann',
    username: 'winh',
    state: 'active',
    avatar_url: 'https://assets.gitlab-static.net/uploads/-/system/user/avatar/1212235/avatar.png',
    web_url: 'https://gitlab.com/winh',
    status_tooltip_html: null,
    path: '/winh',
  },
  active: false,
  coverage: null,
  source: 'push',
  created_at: '2018-11-23T15:05:37.408Z',
  updated_at: '2018-11-23T15:12:47.890Z',
  path: '/gitlab-org/gitlab-ui/pipelines/37691949',
  flags: {
    latest: true,
    stuck: false,
    auto_devops: false,
    yaml_errors: false,
    retryable: true,
    cancelable: false,
    failure_reason: false,
  },
  details: {
    status: {
      icon: 'status_failed',
      text: 'failed',
      label: 'failed',
      group: 'failed',
      tooltip: 'failed',
      has_details: true,
      details_path: '/gitlab-org/gitlab-ui/pipelines/37691949',
      illustration: null,
      favicon:
        'https://gitlab.com/assets/ci_favicons/favicon_status_failed-41304d7f7e3828808b0c26771f0309e55296819a9beea3ea9fbf6689d9857c12.png',
    },
    duration: 427,
    finished_at: '2018-11-23T15:12:47.886Z',
    stages: [
      {
        name: 'build',
        title: 'build: passed',
        groups: [
          {
            name: 'build',
            size: 1,
            status: {
              icon: 'status_success',
              text: 'passed',
              label: 'passed',
              group: 'success',
              tooltip: 'passed',
              has_details: true,
              details_path: '/gitlab-org/gitlab-ui/-/jobs/124722823',
              illustration: {
                image:
                  'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                size: 'svg-430',
                title: 'This job does not have a trace.',
              },
              favicon:
                'https://gitlab.com/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
              action: {
                icon: 'retry',
                title: 'Retry',
                path: '/gitlab-org/gitlab-ui/-/jobs/124722823/retry',
                method: 'post',
                button_title: 'Retry this job',
              },
            },
            jobs: [
              {
                id: 124722823,
                name: 'build',
                started: '2018-11-23T15:05:38.299Z',
                archived: false,
                build_path: '/gitlab-org/gitlab-ui/-/jobs/124722823',
                retry_path: '/gitlab-org/gitlab-ui/-/jobs/124722823/retry',
                playable: false,
                scheduled: false,
                created_at: '2018-11-23T15:05:37.432Z',
                updated_at: '2018-11-23T15:09:00.073Z',
                status: {
                  icon: 'status_success',
                  text: 'passed',
                  label: 'passed',
                  group: 'success',
                  tooltip: 'passed',
                  has_details: true,
                  details_path: '/gitlab-org/gitlab-ui/-/jobs/124722823',
                  illustration: {
                    image:
                      'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                    size: 'svg-430',
                    title: 'This job does not have a trace.',
                  },
                  favicon:
                    'https://gitlab.com/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                  action: {
                    icon: 'retry',
                    title: 'Retry',
                    path: '/gitlab-org/gitlab-ui/-/jobs/124722823/retry',
                    method: 'post',
                    button_title: 'Retry this job',
                  },
                },
              },
            ],
          },
          {
            name: 'update_snapshots',
            size: 1,
            status: {
              icon: 'status_manual',
              text: 'manual',
              label: 'manual play action',
              group: 'manual',
              tooltip: 'manual action',
              has_details: true,
              details_path: '/gitlab-org/gitlab-ui/-/jobs/124722825',
              illustration: {
                image:
                  'https://assets.gitlab-static.net/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                size: 'svg-394',
                title: 'This job requires a manual action',
                content:
                  'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
              },
              favicon:
                'https://gitlab.com/assets/ci_favicons/favicon_status_manual-829a0804612cef47d9efc1618dba38325483657c847dba0546c3b9f0295bb36c.png',
              action: {
                icon: 'play',
                title: 'Play',
                path: '/gitlab-org/gitlab-ui/-/jobs/124722825/play',
                method: 'post',
                button_title: 'Trigger this manual action',
              },
            },
            jobs: [
              {
                id: 124722825,
                name: 'update_snapshots',
                started: null,
                archived: false,
                build_path: '/gitlab-org/gitlab-ui/-/jobs/124722825',
                play_path: '/gitlab-org/gitlab-ui/-/jobs/124722825/play',
                playable: true,
                scheduled: false,
                created_at: '2018-11-23T15:05:37.500Z',
                updated_at: '2018-11-23T15:05:38.093Z',
                status: {
                  icon: 'status_manual',
                  text: 'manual',
                  label: 'manual play action',
                  group: 'manual',
                  tooltip: 'manual action',
                  has_details: true,
                  details_path: '/gitlab-org/gitlab-ui/-/jobs/124722825',
                  illustration: {
                    image:
                      'https://assets.gitlab-static.net/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                    size: 'svg-394',
                    title: 'This job requires a manual action',
                    content:
                      'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
                  },
                  favicon:
                    'https://gitlab.com/assets/ci_favicons/favicon_status_manual-829a0804612cef47d9efc1618dba38325483657c847dba0546c3b9f0295bb36c.png',
                  action: {
                    icon: 'play',
                    title: 'Play',
                    path: '/gitlab-org/gitlab-ui/-/jobs/124722825/play',
                    method: 'post',
                    button_title: 'Trigger this manual action',
                  },
                },
              },
            ],
          },
        ],
        status: {
          icon: 'status_success',
          text: 'passed',
          label: 'passed',
          group: 'success',
          tooltip: 'passed',
          has_details: true,
          details_path: '/gitlab-org/gitlab-ui/pipelines/37691949#build',
          illustration: null,
          favicon:
            'https://gitlab.com/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
        },
        path: '/gitlab-org/gitlab-ui/pipelines/37691949#build',
        dropdown_path: '/gitlab-org/gitlab-ui/pipelines/37691949/stage.json?stage=build',
      },
      {
        name: 'test',
        title: 'test: failed',
        groups: [
          {
            name: 'lint',
            size: 1,
            status: {
              icon: 'status_success',
              text: 'passed',
              label: 'passed',
              group: 'success',
              tooltip: 'passed',
              has_details: true,
              details_path: '/gitlab-org/gitlab-ui/-/jobs/124722827',
              illustration: {
                image:
                  'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                size: 'svg-430',
                title: 'This job does not have a trace.',
              },
              favicon:
                'https://gitlab.com/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
              action: {
                icon: 'retry',
                title: 'Retry',
                path: '/gitlab-org/gitlab-ui/-/jobs/124722827/retry',
                method: 'post',
                button_title: 'Retry this job',
              },
            },
            jobs: [
              {
                id: 124722827,
                name: 'lint',
                started: '2018-11-23T15:09:01.314Z',
                archived: false,
                build_path: '/gitlab-org/gitlab-ui/-/jobs/124722827',
                retry_path: '/gitlab-org/gitlab-ui/-/jobs/124722827/retry',
                playable: false,
                scheduled: false,
                created_at: '2018-11-23T15:05:37.563Z',
                updated_at: '2018-11-23T15:10:55.092Z',
                status: {
                  icon: 'status_success',
                  text: 'passed',
                  label: 'passed',
                  group: 'success',
                  tooltip: 'passed',
                  has_details: true,
                  details_path: '/gitlab-org/gitlab-ui/-/jobs/124722827',
                  illustration: {
                    image:
                      'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                    size: 'svg-430',
                    title: 'This job does not have a trace.',
                  },
                  favicon:
                    'https://gitlab.com/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                  action: {
                    icon: 'retry',
                    title: 'Retry',
                    path: '/gitlab-org/gitlab-ui/-/jobs/124722827/retry',
                    method: 'post',
                    button_title: 'Retry this job',
                  },
                },
              },
            ],
          },
          {
            name: 'visual',
            size: 1,
            status: {
              icon: 'status_failed',
              text: 'failed',
              label: 'failed',
              group: 'failed',
              tooltip: 'failed - (script failure)',
              has_details: true,
              details_path: '/gitlab-org/gitlab-ui/-/jobs/124722831',
              illustration: {
                image:
                  'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                size: 'svg-430',
                title: 'This job does not have a trace.',
              },
              favicon:
                'https://gitlab.com/assets/ci_favicons/favicon_status_failed-41304d7f7e3828808b0c26771f0309e55296819a9beea3ea9fbf6689d9857c12.png',
              action: {
                icon: 'retry',
                title: 'Retry',
                path: '/gitlab-org/gitlab-ui/-/jobs/124722831/retry',
                method: 'post',
                button_title: 'Retry this job',
              },
            },
            jobs: [
              {
                id: 124722831,
                name: 'visual',
                started: '2018-11-23T15:09:01.530Z',
                archived: false,
                build_path: '/gitlab-org/gitlab-ui/-/jobs/124722831',
                retry_path: '/gitlab-org/gitlab-ui/-/jobs/124722831/retry',
                playable: false,
                scheduled: false,
                created_at: '2018-11-23T15:05:37.663Z',
                updated_at: '2018-11-23T15:12:47.315Z',
                status: {
                  icon: 'status_failed',
                  text: 'failed',
                  label: 'failed',
                  group: 'failed',
                  tooltip: 'failed - (script failure)',
                  has_details: true,
                  details_path: '/gitlab-org/gitlab-ui/-/jobs/124722831',
                  illustration: {
                    image:
                      'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                    size: 'svg-430',
                    title: 'This job does not have a trace.',
                  },
                  favicon:
                    'https://gitlab.com/assets/ci_favicons/favicon_status_failed-41304d7f7e3828808b0c26771f0309e55296819a9beea3ea9fbf6689d9857c12.png',
                  action: {
                    icon: 'retry',
                    title: 'Retry',
                    path: '/gitlab-org/gitlab-ui/-/jobs/124722831/retry',
                    method: 'post',
                    button_title: 'Retry this job',
                  },
                },
                recoverable: false,
              },
            ],
          },
        ],
        status: {
          icon: 'status_failed',
          text: 'failed',
          label: 'failed',
          group: 'failed',
          tooltip: 'failed',
          has_details: true,
          details_path: '/gitlab-org/gitlab-ui/pipelines/37691949#test',
          illustration: null,
          favicon:
            'https://gitlab.com/assets/ci_favicons/favicon_status_failed-41304d7f7e3828808b0c26771f0309e55296819a9beea3ea9fbf6689d9857c12.png',
        },
        path: '/gitlab-org/gitlab-ui/pipelines/37691949#test',
        dropdown_path: '/gitlab-org/gitlab-ui/pipelines/37691949/stage.json?stage=test',
      },
      {
        name: 'deploy',
        title: 'deploy: skipped',
        groups: [
          {
            name: 'review',
            size: 1,
            status: {
              icon: 'status_skipped',
              text: 'skipped',
              label: 'skipped',
              group: 'skipped',
              tooltip: 'skipped',
              has_details: true,
              details_path: '/gitlab-org/gitlab-ui/-/jobs/124722835',
              illustration: {
                image:
                  'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                size: 'svg-430',
                title: 'This job has been skipped',
              },
              favicon:
                'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
            },
            jobs: [
              {
                id: 124722835,
                name: 'review',
                started: null,
                archived: false,
                build_path: '/gitlab-org/gitlab-ui/-/jobs/124722835',
                playable: false,
                scheduled: false,
                created_at: '2018-11-23T15:05:37.705Z',
                updated_at: '2018-11-23T15:12:47.805Z',
                status: {
                  icon: 'status_skipped',
                  text: 'skipped',
                  label: 'skipped',
                  group: 'skipped',
                  tooltip: 'skipped',
                  has_details: true,
                  details_path: '/gitlab-org/gitlab-ui/-/jobs/124722835',
                  illustration: {
                    image:
                      'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                    size: 'svg-430',
                    title: 'This job has been skipped',
                  },
                  favicon:
                    'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
                },
              },
            ],
          },
          {
            name: 'review_stop',
            size: 1,
            status: {
              icon: 'status_skipped',
              text: 'skipped',
              label: 'skipped',
              group: 'skipped',
              tooltip: 'skipped',
              has_details: true,
              details_path: '/gitlab-org/gitlab-ui/-/jobs/124722839',
              illustration: {
                image:
                  'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                size: 'svg-430',
                title: 'This job has been skipped',
              },
              favicon:
                'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
            },
            jobs: [
              {
                id: 124722839,
                name: 'review_stop',
                started: null,
                archived: false,
                build_path: '/gitlab-org/gitlab-ui/-/jobs/124722839',
                playable: false,
                scheduled: false,
                created_at: '2018-11-23T15:05:37.926Z',
                updated_at: '2018-11-23T15:12:47.654Z',
                status: {
                  icon: 'status_skipped',
                  text: 'skipped',
                  label: 'skipped',
                  group: 'skipped',
                  tooltip: 'skipped',
                  has_details: true,
                  details_path: '/gitlab-org/gitlab-ui/-/jobs/124722839',
                  illustration: {
                    image:
                      'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                    size: 'svg-430',
                    title: 'This job has been skipped',
                  },
                  favicon:
                    'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
                },
              },
            ],
          },
        ],
        status: {
          icon: 'status_skipped',
          text: 'skipped',
          label: 'skipped',
          group: 'skipped',
          tooltip: 'skipped',
          has_details: true,
          details_path: '/gitlab-org/gitlab-ui/pipelines/37691949#deploy',
          illustration: null,
          favicon:
            'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
        },
        path: '/gitlab-org/gitlab-ui/pipelines/37691949#deploy',
        dropdown_path: '/gitlab-org/gitlab-ui/pipelines/37691949/stage.json?stage=deploy',
      },
      {
        name: 'release',
        title: 'release: skipped',
        groups: [
          {
            name: 'upload_artifacts',
            size: 1,
            status: {
              icon: 'status_skipped',
              text: 'skipped',
              label: 'skipped',
              group: 'skipped',
              tooltip: 'skipped',
              has_details: true,
              details_path: '/gitlab-org/gitlab-ui/-/jobs/124722840',
              illustration: {
                image:
                  'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                size: 'svg-430',
                title: 'This job has been skipped',
              },
              favicon:
                'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
            },
            jobs: [
              {
                id: 124722840,
                name: 'upload_artifacts',
                started: null,
                archived: false,
                build_path: '/gitlab-org/gitlab-ui/-/jobs/124722840',
                playable: false,
                scheduled: false,
                created_at: '2018-11-23T15:05:37.981Z',
                updated_at: '2018-11-23T15:12:47.854Z',
                status: {
                  icon: 'status_skipped',
                  text: 'skipped',
                  label: 'skipped',
                  group: 'skipped',
                  tooltip: 'skipped',
                  has_details: true,
                  details_path: '/gitlab-org/gitlab-ui/-/jobs/124722840',
                  illustration: {
                    image:
                      'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                    size: 'svg-430',
                    title: 'This job has been skipped',
                  },
                  favicon:
                    'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
                },
              },
            ],
          },
        ],
        status: {
          icon: 'status_skipped',
          text: 'skipped',
          label: 'skipped',
          group: 'skipped',
          tooltip: 'skipped',
          has_details: true,
          details_path: '/gitlab-org/gitlab-ui/pipelines/37691949#release',
          illustration: null,
          favicon:
            'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
        },
        path: '/gitlab-org/gitlab-ui/pipelines/37691949#release',
        dropdown_path: '/gitlab-org/gitlab-ui/pipelines/37691949/stage.json?stage=release',
      },
    ],
    artifacts: [
      {
        name: 'visual',
        expired: null,
        expire_at: null,
        path: '/gitlab-org/gitlab-ui/-/jobs/124722831/artifacts/download',
        browse_path: '/gitlab-org/gitlab-ui/-/jobs/124722831/artifacts/browse',
      },
      {
        name: 'build',
        expired: null,
        expire_at: null,
        path: '/gitlab-org/gitlab-ui/-/jobs/124722823/artifacts/download',
        browse_path: '/gitlab-org/gitlab-ui/-/jobs/124722823/artifacts/browse',
      },
    ],
    manual_actions: [
      {
        name: 'update_snapshots',
        path: '/gitlab-org/gitlab-ui/-/jobs/124722825/play',
        playable: true,
        scheduled: false,
      },
      {
        name: 'review_stop',
        path: '/gitlab-org/gitlab-ui/-/jobs/124722839/play',
        playable: false,
        scheduled: false,
      },
    ],
    scheduled_actions: [],
  },
  ref: {
    name: 'winh-search-input',
    path: '/gitlab-org/gitlab-ui/commits/winh-search-input',
    tag: false,
    branch: true,
  },
  commit: {
    id: '36e7ee39823fb2b049cf4e5800133a2dbc202cbb',
    short_id: '36e7ee39',
    title: 'feat: Add search input component',
    created_at: '2018-11-23T15:05:25.000Z',
    parent_ids: ['61444143c09faa3082498f85e5584d5663485bb7'],
    message: 'feat: Add search input component\n',
    author_name: 'Winnie Hellmann',
    author_email: 'winnie@gitlab.com',
    authored_date: '2018-11-21T20:31:22.000Z',
    committer_name: 'Winnie Hellmann',
    committer_email: 'winnie@gitlab.com',
    committed_date: '2018-11-23T15:05:25.000Z',
    author: {
      id: 1212235,
      name: 'Winnie Hellmann',
      username: 'winh',
      state: 'active',
      avatar_url:
        'https://assets.gitlab-static.net/uploads/-/system/user/avatar/1212235/avatar.png',
      web_url: 'https://gitlab.com/winh',
      status_tooltip_html: null,
      path: '/winh',
    },
    author_gravatar_url:
      'https://secure.gravatar.com/avatar/3847071f66fdfeaf35c303a1e41bbb82?s=80\u0026d=identicon',
    commit_url:
      'https://gitlab.com/gitlab-org/gitlab-ui/commit/36e7ee39823fb2b049cf4e5800133a2dbc202cbb',
    commit_path: '/gitlab-org/gitlab-ui/commit/36e7ee39823fb2b049cf4e5800133a2dbc202cbb',
  },
  retry_path: '/gitlab-org/gitlab-ui/pipelines/37691949/retry',
  triggered_by: null,
  triggered: [],
};
