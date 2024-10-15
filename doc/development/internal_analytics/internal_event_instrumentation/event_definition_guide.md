---
stage: Monitor
group: Analytics Instrumentation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Event definition guide

NOTE:
The event dictionary is a work in progress, and this process is subject to change.

This guide describes the event dictionary and how it's implemented.

## Event definition and validation

This process is meant to document all internal events and ensure consistency. Every internal event needs to have such a definition. Event definitions must comply with the [JSON Schema](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/events/schema.json).

All event definitions are stored in the following directories:

- [`config/events`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/config/events)
- [`ee/config/events`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/ee/config/events)

Each event is defined in a separate YAML file consisting of the following fields:

| Field               | Required | Additional information                                                                                                                                                                                                                                                                                                           |
|---------------------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `description`       | yes      | A description of the event.                                                                                                                                                                                                                                                                                                      |
| `internal_events`   | no       | Always `true` for events used in Internal Events.                                                                                                                                                                                                                                                                                |
| `category`          | no       | Required for legacy events. Should not be used for Internal Events.                                                                                                                                                                                                                                                              |
| `action`            | yes      | A unique name for the event. Only lowercase, numbers, and underscores are allowed. Use the format `<operation>_<target_of_operation>_<where/when>`. <br/><br/> Ex: `publish_go_module_to_the_registry_from_pipeline` <br/>`<operation> = publish`<br/>`<target> = go_module`<br/>`<when/where> = to_the_registry_from_pipeline`. |
| `identifiers`       | no       | A list of identifiers sent with the event. Can be set to one or more of `project`, `user`, or `namespace`.                                                                                                                                                                                                                       |
| `product_section`   | yes      | The [section](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/data/sections.yml).                                                                                                                                                                                                                                     |
| `product_stage`     | no       | The [stage](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/stages.yml) for the event.                                                                                                                                                                                                                             |
| `product_group`     | yes      | The [group](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/stages.yml) that owns the event.                                                                                                                                                                                                                       |
| `milestone`         | no       | The milestone when the event is introduced.                                                                                                                                                                                                                                                                                      |
| `introduced_by_url` | no       | The URL to the merge request that introduced the event.                                                                                                                                                                                                                                                                          |
| `distributions`     | yes      | The [distributions](https://handbook.gitlab.com/handbook/marketing/brand-and-product-marketing/product-and-solution-marketing/tiers/#definitions) where the tracked feature is available. Can be set to one or more of `ce` or `ee`.                                                                                             |
| `tiers`             | yes      | The [tiers](https://handbook.gitlab.com/handbook/marketing/brand-and-product-marketing/product-and-solution-marketing/tiers/) where the tracked feature is available. Can be set to one or more of `free`, `premium`, or `ultimate`.                                                                                             |

### Example event definition

This is an example YAML file for an internal event:

```yaml
description: A user visited a product analytics dashboard
internal_events: true
action: visit_product_analytics_dashboard
identifiers:
- project
- user
- namespace
product_section: dev
product_stage: monitor
product_group: group::product analytics
milestone: "16.4"
introduced_by_url: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128029
distributions:
- ee
tiers:
- ultimate
```
