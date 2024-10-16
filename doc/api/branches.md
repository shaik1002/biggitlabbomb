---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Documentation for the REST API for Git branches in GitLab."
---

# Branches API

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

This API operates on [repository branches](../user/project/repository/branches/index.md).

See also [Protected branches API](protected_branches.md).

## List repository branches

Get a list of repository branches from a project, sorted by name alphabetically.

NOTE:
This endpoint can be accessed without authentication if the repository is publicly accessible.

```plaintext
GET /projects/:id/repository/branches
```

Parameters:

| Attribute | Type           | Required | Description |
|:----------|:---------------|:---------|:------------|
| `id`      | integer/string | yes      | ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user.|
| `search`  | string         | no       | Return list of branches containing the search string. You can use `^term` to find branches that begin with `term`, and `term$` to find branches that end with `term`. |
| `regex`   | string         | no       | Return list of branches with names matching a [re2](https://github.com/google/re2/wiki/Syntax) regular expression. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/repository/branches"
```

Example response:

```json
[
  {
    "name": "main",
    "merged": false,
    "protected": true,
    "default": true,
    "developers_can_push": false,
    "developers_can_merge": false,
    "can_push": true,
    "web_url": "https://gitlab.example.com/my-group/my-project/-/tree/main",
    "commit": {
      "id": "7b5c3cc8be40ee161ae89a06bba6229da1032a0c",
      "short_id": "7b5c3cc",
      "created_at": "2012-06-28T03:44:20-07:00",
      "parent_ids": [
        "4ad91d3c1144c406e50c7b33bae684bd6837faf8"
      ],
      "title": "add projects API",
      "message": "add projects API",
      "author_name": "John Smith",
      "author_email": "john@example.com",
      "authored_date": "2012-06-27T05:51:39-07:00",
      "committer_name": "John Smith",
      "committer_email": "john@example.com",
      "committed_date": "2012-06-28T03:44:20-07:00",
      "trailers": {},
      "web_url": "https://gitlab.example.com/my-group/my-project/-/commit/7b5c3cc8be40ee161ae89a06bba6229da1032a0c"
    }
  },
  ...
]
```

## Get single repository branch

Get a single project repository branch.

NOTE:
This endpoint can be accessed without authentication if the repository is publicly accessible.

```plaintext
GET /projects/:id/repository/branches/:branch
```

Parameters:

| Attribute | Type           | Required | Description                                                                                                  |
|:----------|:---------------|:---------|:-------------------------------------------------------------------------------------------------------------|
| `id`      | integer/string | yes      | ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `branch`  | string         | yes      | [URL-encoded name](rest/index.md#namespaced-path-encoding) of the branch.                                                                                          |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/repository/branches/main"
```

Example response:

```json
{
  "name": "main",
  "merged": false,
  "protected": true,
  "default": true,
  "developers_can_push": false,
  "developers_can_merge": false,
  "can_push": true,
  "web_url": "https://gitlab.example.com/my-group/my-project/-/tree/main",
  "commit": {
    "id": "7b5c3cc8be40ee161ae89a06bba6229da1032a0c",
    "short_id": "7b5c3cc",
    "created_at": "2012-06-28T03:44:20-07:00",
    "parent_ids": [
      "4ad91d3c1144c406e50c7b33bae684bd6837faf8"
    ],
    "title": "add projects API",
    "message": "add projects API",
    "author_name": "John Smith",
    "author_email": "john@example.com",
    "authored_date": "2012-06-27T05:51:39-07:00",
    "committer_name": "John Smith",
    "committer_email": "john@example.com",
    "committed_date": "2012-06-28T03:44:20-07:00",
    "trailers": {},
    "web_url": "https://gitlab.example.com/my-group/my-project/-/commit/7b5c3cc8be40ee161ae89a06bba6229da1032a0c"
  }
}
```

## Protect repository branch

See [`POST /projects/:id/protected_branches`](protected_branches.md#protect-repository-branches) for
information on protecting repository branches.

## Unprotect repository branch

See [`DELETE /projects/:id/protected_branches/:name`](protected_branches.md#unprotect-repository-branches)
for information on unprotecting repository branches.

## Create repository branch

Create a new branch in the repository.

```plaintext
POST /projects/:id/repository/branches
```

Parameters:

| Attribute | Type    | Required | Description                                                                                                  |
|:----------|:--------|:---------|:-------------------------------------------------------------------------------------------------------------|
| `id`      | integer | yes      | ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `branch`  | string  | yes      | Name of the branch.                                                                                          |
| `ref`     | string  | yes      | Branch name or commit SHA to create branch from.                                                             |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/repository/branches?branch=newbranch&ref=main"
```

Example response:

```json
{
  "commit": {
    "id": "7b5c3cc8be40ee161ae89a06bba6229da1032a0c",
    "short_id": "7b5c3cc",
    "created_at": "2012-06-28T03:44:20-07:00",
    "parent_ids": [
      "4ad91d3c1144c406e50c7b33bae684bd6837faf8"
    ],
    "title": "add projects API",
    "message": "add projects API",
    "author_name": "John Smith",
    "author_email": "john@example.com",
    "authored_date": "2012-06-27T05:51:39-07:00",
    "committer_name": "John Smith",
    "committer_email": "john@example.com",
    "committed_date": "2012-06-28T03:44:20-07:00",
    "trailers": {},
    "web_url": "https://gitlab.example.com/my-group/my-project/-/commit/7b5c3cc8be40ee161ae89a06bba6229da1032a0c"
  },
  "name": "newbranch",
  "merged": false,
  "protected": false,
  "default": false,
  "developers_can_push": false,
  "developers_can_merge": false,
  "can_push": true,
  "web_url": "https://gitlab.example.com/my-group/my-project/-/tree/newbranch"
}
```

## Delete repository branch

Delete a branch from the repository.

NOTE:
In the case of an error, an explanation message is provided.

```plaintext
DELETE /projects/:id/repository/branches/:branch
```

Parameters:

| Attribute | Type           | Required | Description                                                                                                  |
|:----------|:---------------|:---------|:-------------------------------------------------------------------------------------------------------------|
| `id`      | integer/string | yes      | ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `branch`  | string         | yes      | Name of the branch.                                                                                          |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/repository/branches/newbranch"
```

## Delete merged branches

Deletes all branches that are merged into the project's default branch.

NOTE:
[Protected branches](../user/project/protected_branches.md) are not deleted as part of this operation.

```plaintext
DELETE /projects/:id/repository/merged_branches
```

Parameters:

| Attribute | Type           | Required | Description                                                                                                  |
|:----------|:---------------|:---------|:-------------------------------------------------------------------------------------------------------------|
| `id`      | integer/string | yes      | ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/repository/merged_branches"
```

## Related topics

- [Branches](../user/project/repository/branches/index.md)
- [Protected branches](../user/project/protected_branches.md)
- [Protected branches API](protected_branches.md)
