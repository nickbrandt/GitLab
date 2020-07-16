# GitLab-Workhorse development process

## Maintainers

GitLab-Workhorse has the following maintainers:

- Nick Thomas `@nick.thomas`
- Jacob Vosmaer `@jacobvosmaer-gitlab`
- Alessio Caiazza `@nolith`

This list is defined at https://about.gitlab.com/team/.

## Changelog

GitLab-Workhorse keeps a changelog which is generated when a new release
is created. The changelog is generated from entries that are included on each
merge request. To generate an entry on your branch run:
`_support/changelog "Change descriptions"`.

After the merge request is created, the ID of the merge request needs to be set
in the generated file. If you already know the merge request ID, run:
`_support/changelog -m <ID> "Change descriptions"`.

Any new merge request must contain either a new entry or a justification in the
merge request description why no changelog entry is needed.

## Merging and reviewing contributions

Contributions must be reviewed by at least one Workhorse maintainer.
The final merge must be performed by a maintainer.

## Releases

New versions of Workhorse can be released by one of the Workhorse
maintainers. The release process is:

-   pick a release branch. For x.y.0, use `master`. For all other
    versions (x.y.1, x.y.2 etc.) , use `x-y-stable`. Also see [below](#versioning)
-   run `make tag VERSION=x.y.z"` or `make signed_tag VERSION=x.y.z` on the release branch. This will
    compile the changelog, bump the VERSION file, and make a tag matching it.
-   push the branch and the tag to gitlab.com

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
