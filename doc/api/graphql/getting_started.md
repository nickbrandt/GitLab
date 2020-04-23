# Getting started with GitLab GraphQL API

This guide demonstrates basic usage of GitLab's GraphQL API.

See the [GraphQL API StyleGuide](../../development/api_graphql_styleguide.md) for implementation details
aimed at developers who wish to work on developing the API itself.

## Why GraphQL

GraphQL is a programmatic language for easily accessing and manipulating complex data in a single
request with an intuitive and flexible syntax. With a single request, you can receive a tailored
response coming from multiple data sources. This approach minimizes the traditional effort of
client-side coding against multiple APIs, reduces bandwidth, and improves response times.

Additional benefits include:

1. Representing data as a graph for easier traversal.
1. Single endpoint with a machine-readable schema file reduces versioning complexity.
1. Allow the client to request only the data it needs and nothing more.
1. Facilitate investigative querying of data.

### GraphQL vs REST

For over 15 years, [REST](https://en.wikipedia.org/wiki/Representational_state_transfer) has been a
standard, object-based way to programmatically access data on remote servers.

REST is widely used and has many benefits. It provides a fixed-interaction interface with specific
operations such as `POST`, `GET`, `DELETE`, and others. But the basic premise is to expose the
object structure to make it object oriented. Relationships are represented as identifiers that can
be used to get more information. Each retrieval requires a new query. REST therefore performs well
when attempting to tie complex objects together with step-by-step data retrieval. But with modern
approaches to retrieve more than a single object, retrieval requires modification of the object
interface or multiple calls. For example, attempting to present data on a single-page application
(SPA) that may have information sourced from multiple objects can increase the complexity of the
front-end code.

TODO (mike): proof point examples & challenges with multiple queries.  GraphQL is a new framework/standard for single query, server-side access to multiple data sources.

TODO (Mike)
-performance
-value
- cheaper than joins from tabulated data
- reduce bandwith

### Proof Point

As an example, consider the following situation:

You just discovered a bug in the production system. All logs indicate that an issue you worked on
and closed during the 2019 winter break caused it. Viewed alone, your work seems fine. However, the
bug surfaces due to the interaction between what you and others did. To resolve this, you must
identify all the issues that were in the same epic, find out who they were assigned to, and then
collaborate with those developers to fix the problem.

Attempting this through REST would require multiple calls.  In this example, this would entail:
a. Identify the project ID that you want to start with
```shell
curl --location --header 'PRIVATE-TOKEN: $PERSONAL_TOKEN' --request GET 'https://gitlab.example.com/api/v4/projects/:id' 
```
b. Query all issues for a given project closed prior to January 1, 2020
```shell
curl --location --header 'PRIVATE-TOKEN: $PERSONAL_TOKEN' --request GET 'https://gitlab.example.com/api/v4/projects/:id/issues?state=closed&created_before=2020-01-01&assignee_id=any' 
```
c. Get the Epic that those issues belong to.  This will require parsing the Epic Ids

d. Find the issues in that epic (this query will require knowledge of the group the epic is in)
```shell
curl --location --header 'PRIVATE-TOKEN: $PERSONAL_TOKEN' --request GET 'https://gitlab.example.com/api/v4/groups/:id/epics/:epic_iid/issues'
```

Compare this to the single GraphQL query  
```shell
curl --location --request POST 'https://gitlab.example.com/api/graphql' \
--header 'Authorization: Bearer $PERSONAL_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{"query":"{
                project(fullPath: \"group/subgroup/project\") {
                issues(state: closed, createdBefore: \"2020-01-01\", sort: created_asc, assigneeId: \"any\") {      
                  nodes {
                    iid
                    state
                    createdAt
                    closedAt
                    title
                    epic {
                      id
                      title
                      issues{
                          nodes{
                            id
                            state
                            title
                          }
                      }
                    }
                    assignees {
                      nodes {
                        name
                      }
                    }
                  }
                }
              }
           }","variables":{}}'
```



3 level deep queries; anonymized customer example
TODO: show 3 real _anonymized_ examples that show the frustration/performance impact of client-side processing

TODO (jr): anonymized telecom example

TODO (dt): A Customer in Service Management needs to aggregate test case results, for individual piplelines, across various projects.   TODO: example?

## Examples

The examples documented here can be run using:

- The command line.
- GraphiQL.

TODO:  
*  current helloworld
* consuming a datafile with a lengthy query e.g. from GiQL
* filtering and analyzing the the output from the CLI
* adding this to automation e.g.  gitlab-ci.yml

### Using GraphiQL
TODO: highlight graphiQL; how to get the data back into reality :)  Take something from GiQL (curl) and paste it

### Command line

You can run GraphQL queries in a `curl` request on the command line on your local machine.
A GraphQL request can be made as a `POST` request to `/api/graphql` with the query as the payload.
You can authorize your request by generating a [personal access token](../../user/profile/personal_access_tokens.md)
to use as a bearer token.

Example:

```shell
GRAPHQL_TOKEN=<your-token>
curl 'https://gitlab.com/api/graphql' --header "Authorization: Bearer $GRAPHQL_TOKEN" --header "Content-Type: application/json" --request POST --data "{\"query\": \"query {currentUser {name}}\"}"
```
TODO (jr/mike/dt/sameer)
#1 current helloworld
#2 consuming a datafile with a lengthy query e.g. from GiQL
#3 filtering and analyzing the the output from the CLI
#4 adding this to automation e.g.  gitlab-ci.yml

TODO: shell examples

### GraphiQL

GraphiQL (pronounced “graphical”) allows you to run queries directly against the server endpoint
with syntax highlighting and autocomplete. It also allows you to explore the schema and types.

The examples below:

- Can be run directly against GitLab 11.0 or later, though some of the types and fields
may not be supported in older versions.
- Will work against GitLab.com without any further setup. Make sure you are signed in and
navigate to the [GraphiQL Explorer](https://gitlab.com/-/graphql-explorer).

If you want to run the queries locally, or on a self-managed instance,
you will need to either:

- Create the `gitlab-org` group with a project called `graphql-sandbox` under it. Create
several issues within the project.
- Edit the queries to replace `gitlab-org/graphql-sandbox` with your own group and project.

Please refer to [running GraphiQL](index.md#graphiql) for more information.

NOTE: **Note:**
If you are running GitLab 11.0 to 12.0, enable the `graphql`
[feature flag](../features.md#set-or-create-a-feature).

## Queries and mutations

The GitLab GraphQL API can be used to perform:

- Queries for data retrieval.
- [Mutations](#mutations) for creating, updating, and deleting data.

NOTE: **Note:**
In the GitLab GraphQL API, `id` generally refers to a global ID,
which is an object identifier in the format of `gid://gitlab/Issue/123`.

[GitLab's GraphQL Schema](reference/index.md) outlines which objects and fields are
available for clients to query and their corresponding data types.

Example: Get only the names of all the projects the currently logged in user can access (up to a limit, more on that later)
in the group `gitlab-org`.

```graphql
query {
  group(fullPath: "gitlab-org") {
    id
    name
    projects {
      nodes {
        name
      }
    }
  }
}
```

Example: Get a specific project and the title of Issue #2.

```graphql
query {
  project(fullPath: "gitlab-org/graphql-sandbox") {
    name
    issue(iid: "2") {
      title
    }
  }
}
```

### Graph traversal

When retrieving child nodes use:

- the `edges { node { } }` syntax.
- the short form `nodes { }` syntax.

Underneath it all is a graph we are traversing, hence the name GraphQL.

Example: Get a project (only its name) and the titles of all its issues.

```graphql
query {
  project(fullPath: "gitlab-org/graphql-sandbox") {
    name
    issues {
      nodes {
        title
        description
      }
    }
  }
}
```

More about queries:
[GraphQL docs](https://graphql.org/learn/queries/)

### Authorization

Authorization uses the same engine as the GitLab application (and GitLab.com). So if you've signed in to GitLab
and use GraphiQL, all queries will be performed as you, the signed in user. For more information, see the
[GitLab API documentation](../README.md#authentication).

### Mutations

Mutations make changes to data. We can update, delete, or create new records. Mutations
generally use InputTypes and variables, neither of which appear here.

Mutations have:

- Inputs. For example, arguments, such as which emoji you'd like to award,
and to which object.
- Return statements. That is, what you'd like to get back when it's successful.
- Errors. Always ask for what went wrong, just in case.

#### Creation mutations

Example: Let's have some tea - add a `:tea:` reaction emoji to an issue.

```graphql
mutation {
  addAwardEmoji(input: { awardableId: "gid://gitlab/Issue/27039960",
      name: "tea"
    }) {
    awardEmoji {
      name
      description
      unicode
      emoji
      unicodeVersion
      user {
        name
      }
    }
    errors
  }
}
```

Example: Add a comment to the issue (we're using the ID of the `GitLab.com` issue - but
if you're using a local instance, you'll need to get the ID of an issue you can write to).

```graphql
mutation {
  createNote(input: { noteableId: "gid://gitlab/Issue/27039960",
      body: "*sips tea*"
    }) {
    note {
      id
      body
      discussion {
        id
      }
    }
    errors
  }
}
```

#### Update mutations

When you see the result `id` of the note you created - take a note of it. Now let's edit it to sip faster!

```graphql
mutation {
  updateNote(input: { id: "gid://gitlab/Note/<note id>",
      body: "*SIPS TEA*"
    }) {
    note {
      id
      body
    }
    errors
  }
}
```

#### Deletion mutations

Let's delete the comment, since our tea is all gone.

```graphql
mutation {
  destroyNote(input: { id: "gid://gitlab/Note/<note id>" }) {
    note {
      id
      body
    }
    errors
  }
}
```

You should get something like the following output:

```json
{
  "data": {
    "destroyNote": {
      "errors": [],
      "note": null
    }
  }
}
```

We've asked for the note details, but it doesn't exist anymore, so we get `null`.

More about mutations:
[GraphQL Docs](https://graphql.org/learn/queries/#mutations).

### Introspective queries

Clients can query the GraphQL endpoint for information about its own schema.
by making an [introspective query](https://graphql.org/learn/introspection/).

It is through an introspection query that the [GraphiQL Query Explorer](https://gitlab.com/-/graphql-explorer)
gets all of its knowledge about our GraphQL schema to do autocompletion and provide
its interactive `Docs` tab.

Example: Get all the type names in the schema.

```graphql
{
  __schema {
    types {
      name
    }
  }
}
```

Example: Get all the fields associated with Issue.
`kind` tells us the enum value for the type, like `OBJECT`, `SCALAR` or `INTERFACE`.

```graphql
query IssueTypes {
  __type(name: "Issue") {
    kind
    name
    fields {
      name
      description
      type {
        name
      }
    }
  }
}
```

More about introspection:
[GraphQL docs](https://graphql.org/learn/introspection/)

## Sorting

Some of GitLab's GraphQL endpoints allow you to specify how you'd like a collection of
objects to be sorted. You can only sort by what the schema allows you to.

Example: Issues can be sorted by creation date:

```graphql
query {
  project(fullPath: "gitlab-org/graphql-sandbox") {
   name
    issues(sort: created_asc) {
      nodes {
        title
        createdAt
      }
    }
  }
}
```

## Pagination

Pagination is a way of only asking for a subset of the records (say, the first 10).
If we want more of them, we can make another request for the next 10 from the server
(in the form of something like "please give me the next 10 records").

By default, GitLab's GraphQL API will return only the first 100 records of any collection.
This can be changed by using `first` or `last` arguments. Both arguments take a value,
so `first: 10` will return the first 10 records, and `last: 10` the last 10 records.

Example: Retrieve only the first 2 issues (slicing). The `cursor` field gives us a position from which
we can retrieve further records relative to that one.

```graphql
query {
  project(fullPath: "gitlab-org/graphql-sandbox") {
    name
    issues(first: 2) {
      edges {
        node {
          title
        }
      }
      pageInfo {
        endCursor
        hasNextPage
      }
    }
  }
}
```

Example: Retrieve the next 3. (The cursor value
`eyJpZCI6IjI3MDM4OTMzIiwiY3JlYXRlZF9hdCI6IjIwMTktMTEtMTQgMDU6NTY6NDQgVVRDIn0`
could be different, but it's the `cursor` value returned for the second issue returned above.)

```graphql
query {
  project(fullPath: "gitlab-org/graphql-sandbox") {
    name
    issues(first: 3, after: "eyJpZCI6IjI3MDM4OTMzIiwiY3JlYXRlZF9hdCI6IjIwMTktMTEtMTQgMDU6NTY6NDQgVVRDIn0") {
      edges {
        node {
          title
        }
        cursor
      }
      pageInfo {
        endCursor
        hasNextPage
      }
    }
  }
}
```

More on pagination and cursors:
[GraphQL docs](https://graphql.org/learn/pagination/)
