# GitLab-Workhorse development process

## Maintainers

GitLab-Workhorse has the following maintainers:

- Nick Thomas `@nick.thomas`
- Jacob Vosmaer `@jacobvosmaer-gitlab`

This list is defined at https://about.gitlab.com/team/.

## Merging and reviewing contributions

Contributions must be reviewed by at least one Workhorse maintainer.
The final merge must be performed by a maintainer.

## Releases

New versions of Workhorse can be released by one of the Workhorse
maintainers. The release process is:

- create a merge request to update CHANGELOG and VERSION on the
  respective release branch (usually `master`)
- merge the merge request
- run `make release` on the release branch
