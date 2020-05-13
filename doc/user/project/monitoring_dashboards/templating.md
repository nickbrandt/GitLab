---
stage: Monitor
group: APM
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Templating

Templating variables can be used to make your dashboard more versatile.

## Templating variable types

`templating` is a top-level key in the [dashboard YAML](../integrations/prometheus.md#dashboard-top-level-properties).

The `variables` key under `templating` is where all your variables should be defined.

The value of the `variables` key should be a hash. Each key under `variables`
defines a templating variable on the dashboard.

A variable can be used in a Prometheus query in the same dashboard using the syntax
described [here](../integrations/prometheus.md#using-variables).

### `text` variable type

CAUTION: **Warning:**
This is an _alpha_ feature, and is subject to change at any time without
prior notice!

For each `text` variable defined in the dashboard YAML, there will be a free text
box on the dashboard UI, allowing the user to enter a value for each variable.

The `text` variable type supports a simple and a full syntax.

#### Simple syntax

```yaml
templating:
  variables:
    variable1: 'default value'     # `text` type variable with `default value` as its default.
```

This creates a variable called `variable1`, with a default value of `default value`.

#### Full syntax

```yaml
templating:
  variables:
    variable1:                       # The variable name that can be used in queries.
      label: 'Variable 1'            # (Optional) label that will appear in the UI for this text box.
      type: text
      options:
        default_value: 'default'     # (Optional) default value.
```

This creates a variable called `variable1`, with a default value of `default`.
The label for the text box on the UI will be the value of the `label` key.

### `custom` variable type

CAUTION: **Warning:**
This is an _alpha_ feature, and is subject to change at any time without
prior notice!

For each `custom` variable defined in the dashboard YAML, there will be a dropdown
selector on the dashboard UI, allowing the user to select a value for each variable.

The `custom` variable type supports a simple and a full syntax.

#### Simple syntax

```yaml
templating:
  variables:
    variable1: ['value1', 'value2', 'value3']
```

This creates a variable called `variable1`, with a default value of `value1`.
The dashboard UI will have a dropdown where `value1`, `value2` and `value3` will
be the choices.

#### Full syntax

```yaml
templating:
  variables:
    variable1:                           # The variable name that can be used in queries.
      label: 'Variable 1'                # (Optional) label that will appear in the UI for this dropdown.
      type: custom
      options:
        values:
        - value: 'value option 1'        # The value that will replace the variable in queries.
          text: 'Option 1'               # (Optional) Text that will appear in the UI dropdown.
        - value: 'value_option_2'
          text: 'Option 2'
          default: true                  # (Optional) This option should be the default value of this variable.
```

This creates a variable called `variable1`, with a default value of `var1_option_2`.
The label for the text box on the UI will be the value of the `label` key.
The dashboard UI will have a dropdown where `Option 1` and `Option 2`
will be the choices.

If you select `Option 1` from the dropdown, the variable will be replaced with `value option 1`.
Similarly, if you select `Option 2`, the variable will be replaced with `value_option_2`.
