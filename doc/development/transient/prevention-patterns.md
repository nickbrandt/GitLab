---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Preventing Transient Bugs

This page will cover architectural patterns and tips for developers to follow to prevent transient bugs.

## Frontend

### Don't rely on response order

When working with multiple requests, it's easy to assume the order of the responses will match the order in which they are triggered.

That's not always the case and can cause bugs that only happen if the order is switched.

**Example:**

- `diffs_metadata.json` (lighter)
- `diffs_batch.json` (heavier)

If your feature requires data from both, ensure that the two have finished loading before working on it.

### Simulate slower connetions when testing manually

Add a network condition template to your browser's dev tools to enable you to toggle between a slow and a fast connection.

**Example:**

- Turtle:
  - Down: 50kb/s
  - Up: 20kb/s
  - Latency: 10000ms

### Collapsed elements

When setting event listeners, if not possible to use event delegation, ensure all relevant event listeners are set for expanded content.

Including when that expanded content is:

- **Invisible** (`display: none;`). Some JavaScript requires the element to be visible to work properly (eg.: when taking measurements).
- **Dynamic content** (AJAX/DOM manipulation).

### Using assertions to detect transient bugs caused by unmet conditions

Transient bugs happen in the context of code that executes under the assumption
that the application’s state meets one or more conditions. We may write a feature
that assumes a server-side API response always include a group of attributes or that
an operation only executes when the application has successfully transitioned to a new
state.

Transient bugs are difficult to debug because there isn’t any mechanism that alerts
the user or the developer about unsatisfied conditions. These conditions are usually
not expressed explicitly in the code. A useful debugging technique for such situations
is placing assertions to make any assumption explicit. They can help detect the cause
which unmet condition causes the bug.

**Asserting pre-conditions on state mutations**

A common scenario that leads to transient bugs is when there is a polling service
that should mutate state only if a user operation is completed. We can use
assertions to make this pre-condition explicit:

```javascript
// This action is called by a polling service. It assumes that all pre-conditions
// are satisfied by the time the action is dispatched.
export const updateMergeableStatus = ({ commit }, payload) => {
  commit(types.SET_MERGEABLE_STATUS, payload);
};

// We can make any pre-condition explicit by adding an assertion
export const updateMergeableStatus = ({ state, commit }, payload) => {
  console.assert(
    state.isResolvingDiscussion === true,
    'Resolve discussion request must be completed before updating mergeable status'
  );
  commit(types.SET_MERGEABLE_STATUS, payload);
};
```

**Asserting API contracts**

Another useful way of using assertions is to detect if the response payload returned
by the server-side endpoint satisfies the API contract.

**Related reading**

[Debug it!](https://pragprog.com/titles/pbdp/debug-it/) explores techniques to diagnose
and fix non-determinstic bugs and write software that is easier to debug.
