import state from 'ee/operations/store/state';

export function clearState(store) {
  store.replaceState(state());
}

export function getChildInstances(vm, WrappedComponent) {
  return vm.$children.filter(child => child instanceof WrappedComponent);
}

export function mouseEvent(el, eventType) {
  const event = document.createEvent('MouseEvent');
  event.initMouseEvent(eventType);
  el.dispatchEvent(event);
}
