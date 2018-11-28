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
- make sure the new version number adheres to our [versioning standard](#versioning)
- merge the merge request
- run `make release` on the release branch

## Versioning

Workhorse uses a variation of SemVer. We don't use "normal" SemVer
because we have to be able to integrate into GitLab stable branches.

A version has the format MAJOR.MINOR.PATCH.

- Major and minor releases are tagged on the `master` branch
- If the change is backwards compatible, increment the MINOR counter
- If the change breaks compatibility, increment MAJOR and set MINOR to `0`
- Patch release tags must be made on stable branches
- Only make a patch release when targeting a GitLab stable branch

This means that tags that end in `.0` (e.g. `8.5.0`) must always be on
the master branch, and tags that end in anthing other than `.0` (e.g.
`8.5.2`) must always be on a stable branch.

> The reason we do this is that SemVer suggests something like a
> refactoring constitutes a "patch release", while the GitLab stable
> branch quality standards do not allow for back-porting refactorings
> into a stable branch.
