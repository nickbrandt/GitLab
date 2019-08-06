import Vue from 'vue';
import requestSelector from '~/performance_bar/components/request_selector.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('request selector', () => {
  const requests = [
    {
      id: '123',
      url: 'https://gitlab.com/',
      hasWarnings: false,
    },
    {
      id: '456',
      url: 'https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/1',
      hasWarnings: false,
    },
    {
      id: '789',
      url: 'https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/1.json?serializer=widget',
      hasWarnings: false,
    },
    {
      id: 'abc',
      url: 'https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/1/discussions.json',
      hasWarnings: true,
    },
  ];

  let vm;

  beforeEach(() => {
    vm = mountComponent(Vue.extend(requestSelector), {
      requests,
      currentRequest: requests[1],
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  function optionText(requestId) {
    return vm.$el.querySelector(`[value='${requestId}']`).innerText.trim();
  }

  it('displays the last component of the path', () => {
    expect(optionText(requests[2].id)).toEqual('1.json?serializer=widget');
  });

  it('keeps the last two components of the path when the last component is numeric', () => {
    expect(optionText(requests[1].id)).toEqual('merge_requests/1');
  });

  it('ignores trailing slashes', () => {
    expect(optionText(requests[0].id)).toEqual('gitlab.com');
  });

  it('has a warning icon if any requests have warnings', () => {
    expect(vm.$el.querySelector('span > gl-emoji').dataset.name).toEqual('warning');
  });

  it('adds a warning icon to requests with warnings', () => {
    const option = vm.$el.querySelector('[value="abc"]');

    expect(option.querySelector('gl-emoji').dataset.name).toEqual('warning');
    expect(option.innerText).toContain('discussions.json');
  });
});
