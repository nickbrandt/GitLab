/**
 * @deprecated
 * DO NOT USE! This causes issues when `vue-test-utils` is used elsewhere.
 * This function will be removed in https://gitlab.com/gitlab-org/gitlab/issues/9594.
 */
export function getChildInstances(vm, WrappedComponent) {
  return vm.$children.filter(child => child instanceof WrappedComponent);
}

export function mouseEvent(el, eventType) {
  const event = document.createEvent('MouseEvent');
  event.initMouseEvent(eventType);
  el.dispatchEvent(event);
}
