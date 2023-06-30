---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Naming

Since we often have people looking at and working on tests they did not write, having a consistant naming makes it easier for those who didn't write the tests to understand and work on. Our [testing guide](index.md) extends the [Thoughtbot testing style guide](https://github.com/thoughtbot/guides/tree/master/testing-rspec). This page clarifies the guidelines, along with input from [https://www.betterspecs.org/](https://www.betterspecs.org/) and [the RSpec naming guide](https://rspec.rubystyle.guide/#naming.)

## Context Descriptions

1. Every `describe`, `context`, and `it` blocks should have a short description attached
1. Keep description shorter than 60 characters.
    1. if it is longer or you have multiple conditionals, that is a sign it should be split up (additional `context` blocks)
1. The outermost `Rspec.describe` block should be [the DevOps stage name](https://about.gitlab.com/handbook/product/categories/#devops-stages)
1. Inside that block is a `describe` block with the name of the feature being tested
1. Inside that block are `context` blocks with names that define what the conditions being tested are
    1. `context` blocks descriptions should begin with `when`, `with`, `without`, `for`, `and`, `on`, `in`, `as`, or `if` to match the [rubocop rule](https://www.rubydoc.info/gems/rubocop-rspec/RuboCop/Cop/RSpec/ContextWording)
    1. if the test is simple enough and does not need conditional blocks, `context` blocks may not be needed
1. the innermost is the `it` block with a name that defines the pass/fail criteria for the test
    1. A `specify` block can be used instead of a named `it` block if the test is simple enough

## Example Description

```mermaid
graph LR
   A(rspec.describe) --> B(describe) 
   B -- optional --> C(context)
    B --> D(it / specify)
    C --> D
    C --> C
```

This diagram shows conceptually how the elements used in creating a test name are nested. If you are using `shared_examples` the actual sequence in the code may be different ([an example](https://gitlab.com/gitlab-org/gitlab/-/blob/master/qa/qa/specs/features/browser_ui/9_data_stores/project/create_project_spec.rb)) but when RSpec runs it calls the code in that order.

An example:

```
RSpec.describe 'Plan', product_group: :knowledge do
  describe 'wiki content creation' do
    context 'when inside a project'
      it 'successfully adds a home page'
      ...
      end
    ...
    end
  ...
  end
end
```

Will generate a test with the name of `Plan wiki content creation when inside a project successfully adds a home page`
