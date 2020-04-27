import Vue from 'vue';
import vulnerabilitiesEventBus from 'ee/vulnerabilities/components/vulnerabilities_event_bus';

describe('Vulnerabilities event bus', () => {
  it('default exports a vue instance', () => {
    expect(vulnerabilitiesEventBus instanceof Vue).toBe(true);
  });
});
