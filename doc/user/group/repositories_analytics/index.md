---
type: reference
stage: Verify
group: Analytics
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Repositories Analytics **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/215104) in [GitLab Premium](https://about.gitlab.com/pricing/) 13.3.

To get a CSV of the code coverage data for all of the projects in your group, go to your group's **Analytics > CI/CD** page

Each row in the provided CSV includes:

- The date when the coverage was calculated (at most one per day, from the latest run that day)
- The name of the project
- The name of the job that generated the coverage report
- The coverage value

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
