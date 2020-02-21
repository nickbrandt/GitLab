# Release post data file for Primary items
# DELETE THESE COMMENTS BEFORE MERGING
#
# Note:
# - All description entries support markdown. Use it as you do for a regular markdown file.
#   Just make sure the indentation is respected.
#
## Entries:
#
# - name: "Amazing Feature" # feature name: make it consistent, use the same name here, in the features.yml file, and in the docs
# - available_in: [core, starter, premium, ultimate]
# - gitlab_com: false # apply this for features not available in GitLab.com
# - documentation_link: 'https://docs.gitlab.com/ee/#amazingdoc' # up-to-date documentation - required
# - image_url: '/images/x_y/feature-a.png' # required, but can be replaced with a video
# - image_noshadow: true # this eliminates double shadows for images that already have a shadow
# - video: 'https://www.youtube.com/embed/enMumwvLAug' # overrides image_url - use the "embed" link (not required)
# - reporter: pm1 # GitLab handle of the user adding the feature block in the list (not the feature author)
# - stage: stagename # DevOps stage the feature belongs to
#          Example => stage: secure (lowercase, omit the leading 'devops::' part of the label)
#                     see https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/development/contributing/issue_workflow.md#stage-labels
# - categories:
# - - 'category name'
# - - 'optional second category'
# - - 'etc'
#          Information => Legal values come from the /data/categories.yml file from the entries titled 'name:'
#          Example => In /data/categories.yml
#                        issue_tracking:
#                          name: Issue Tracking   <== Use 'Issue Tracking' as the category
# - issue_url: 'https://gitlab.com/gitlab-org/gitlab-ce/issues/12345' # link to the issue on GitLab.com where the feature is discussed and developed - required but replaceable with epic_url or mr_url
# - issueboard_url: 'https://gitlab.com/group/project/boards/123?=' # link to the issue board for the feature (not required)
# - epic_url: 'https://gitlab.com/groups/gitlab-org/-/epics/123' # link to the epic for the feature (not required)
# - mr_url: 'https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/123' # link to the MR that introduced the feature (not required)
# - webpage_url: '/features/gitlab-geo/' # link to the marketing webpage for a given feature (not required)
#
# Read through the Release Posts Handbook for more information:
# https://about.gitlab.com/handbook/marketing/blog/release-posts/
#
# ATTENTION: Leave these instructions and the example blocks (with their inline comments)
# up until the time the review starts. Once you've added an item, and **only by then**,
# please remove the inline comment to indicate that the item has been updated, thus
# we can clear up the comments on the go and easily spot what's missing.
###
features:
  primary:
    - name: "Lorem ipsum"
      available_in: [core, starter, premium, ultimate]
      gitlab_com: false
      documentation_link: 'https://docs.gitlab.com/ee/#amazing'
      image_url: '/images/unreleased/feature-a.png'
      reporter: pm1
      stage: plan
      categories:
        - 'Category name goes here. Only one is required. Add/delete other categories as needed.'
        - 'optional second category'
        - 'etc'
      issue_url: ''
      description: |
        Lorem ipsum [dolor sit amet](#link), consectetur adipisicing elit.
        Perferendis nisi vitae quod ipsum saepe cumque quia `veritatis`.
