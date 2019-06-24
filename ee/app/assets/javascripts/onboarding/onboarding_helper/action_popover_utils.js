import Vue from 'vue';
import ActionPopover from './components/action_popover.vue';

// retry for 10 times (5 seconds in total)
const maxTries = 10;
const timeout = 500;

const mountComponent = (intervalId, el, { target, content, placement, showPopover }) => {
  clearInterval(intervalId);

  return new Vue({
    el,
    render(h) {
      return h(ActionPopover, {
        props: {
          target,
          content,
          placement,
          showDefault: showPopover,
        },
      });
    },
  });
};

const renderPopover = (popoverSelector, content, placement, showPopover) => {
  const popoverContainer = document.getElementById('js-onboarding-action-popover');
  let retry = 0;

  if (!popoverContainer) {
    return false;
  }

  // continuously check if target element already exists (might be delayed to to dynamic component creation)
  const intervalId = setInterval(() => {
    if (retry >= maxTries) {
      clearInterval(intervalId);
    }
    retry += 1;

    const target = document.querySelector(popoverSelector);

    if (!target) {
      return false;
    }

    return mountComponent(intervalId, popoverContainer, {
      target,
      content,
      placement,
      showPopover,
    });
  }, timeout);

  return intervalId;
};

const actionPopoverUtils = {
  renderPopover,
};

export default actionPopoverUtils;
