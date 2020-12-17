---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference
description: "Autocomplete characters in Markdown fields."
---

# Autocomplete characters **(CORE)**

The autocomplete characters provide a quick way of entering field values into
Markdown fields. When you start typing a word in a Markdown field with one of
the following characters, GitLab progressively autocompletes against a set of
matching values. The string matching is not case sensitive.

| Character     | Autocompletes |
| :------------ | :------------ |
| `~`           | [Labels](labels.md) |
| `%`           | [Milestones](milestones/index.md) |
| `@`           | Users and groups |
| `#`           | [Issues](issues/index.md) |
| `!`           | [Merge requests](merge_requests/index.md) |
| `&`           | [Epics](../group/epics/index.md) |
| `$`           | [Snippets](../snippets.md) |
| `:`           | [Emoji](../markdown.md#emoji) |
| `/`           | [Quick Actions](quick_actions.md) |
| `*iteration:` | [Iterations.](../group/iterations/index.md) To learn how to enable it, go to [Autocomplete for Iterations](#autocomplete-for-iterations). **(STARTER)** |

Up to 5 of the most relevant matches are displayed in a popup list. When you
select an item from the list, the value is entered in the field. The more
characters you enter, the more precise the matches are.

Autocomplete characters are useful when combined with [Quick Actions](quick_actions.md).

## Example

Assume your GitLab instance includes the following users:

<!-- vale gitlab.Spelling = NO -->

| Username        | Name |
| :-------------- | :--- |
| alessandra      | Rosy Grant |
| lawrence.white  | Kelsey Kerluke |
| leanna          | Rosemarie Rogahn |
| logan_gutkowski | Lee Wuckert |
| shelba          | Josefine Haley |

<!-- vale gitlab.Spelling = YES -->

In an Issue comment, entering `@l` results in the following popup list
appearing. Note that user `shelba` is not included, because the list includes
only the 5 users most relevant to the Issue.

![Popup list which includes users whose username or name contains the letter `l`](img/autocomplete_characters_example1_v12_0.png)

If you continue to type, `@le`, the popup list changes to the following. The
popup now only includes users where `le` appears in their username, or a word in
their name.

![Popup list which includes users whose username or name contains the string `le`](img/autocomplete_characters_example2_v12_0.png)

## Autocomplete for Iterations **(STARTER)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/232601) in GitLab 13.7.
> - It's deployed behind a feature flag, disabled by default.
> - It's disabled for GitLab.com.
> - It's not recommended for production use.
> - To use it in GitLab self-managed instances, ask a GitLab administrator to [enable it](#enable-or-disable-autocomplete-for-iterations) **(STARTER ONLY)**

WARNING:
This feature might not be available to you. Check the **version history** note above for details.

Autocomplete became available for [Iterations](../group/iterations/index.md)
in GitLab 13.7. You can type `*iteration:` and GitLab prompts you with relevant results.

### Enable or disable autocomplete for Iterations **(STARTER ONLY)**

Autocomplete for Iterations is under development and not ready for production use. It is
deployed behind a feature flag that is **disabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../administration/feature_flags.md)
can enable it.

To enable it:

```ruby
Feature.enable(:tribute_autocomplete)
```

To disable it:

```ruby
Feature.disable(:tribute_autocomplete)
```
