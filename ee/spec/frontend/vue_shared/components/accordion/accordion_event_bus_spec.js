import Vue from 'vue';
import accordionEventBus from 'ee/vue_shared/components/accordion/accordion_event_bus';

describe('Accordion event bus', () => {
  it('default exports a vue instance', () => {
    expect(accordionEventBus instanceof Vue).toBe(true);
  });
});
