import { GlBreadcrumb } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import LegacyContainer from '~/vue_shared/new_namespace/components/legacy_container.vue';
import WelcomePage from '~/vue_shared/new_namespace/components/welcome.vue';
import NewNamespacePage from '~/vue_shared/new_namespace/new_namespace_page.vue';

describe('Experimental new project creation app', () => {
  let wrapper;

  const DEFAULT_PROPS = {
    title: 'Create something',
    initialBreadcrumb: 'Something',
    panels: [
      { name: 'panel1', selector: '#some-selector1' },
      { name: 'panel2', selector: '#some-selector2' },
    ],
    persistenceKey: 'DEMO-PERSISTENCE-KEY',
  };

  const createComponent = ({ slots, propsData } = {}) => {
    wrapper = shallowMount(NewNamespacePage, {
      slots,
      propsData: {
        ...DEFAULT_PROPS,
        ...propsData,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    window.location.hash = '';
    wrapper = null;
  });

  it('passes experiment to welcome component if provided', () => {
    const EXPERIMENT = 'foo';
    createComponent({ propsData: { experiment: EXPERIMENT } });

    expect(wrapper.findComponent(WelcomePage).props().experiment).toBe(EXPERIMENT);
  });

  describe('with empty hash', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders welcome page', () => {
      expect(wrapper.findComponent(WelcomePage).exists()).toBe(true);
    });

    it('does not render breadcrumbs', () => {
      expect(wrapper.findComponent(GlBreadcrumb).exists()).toBe(false);
    });
  });

  it('renders first container if jumpToLastPersistedPanel passed', () => {
    createComponent({ propsData: { jumpToLastPersistedPanel: true } });
    expect(wrapper.findComponent(WelcomePage).exists()).toBe(false);
    expect(wrapper.findComponent(LegacyContainer).exists()).toBe(true);
  });

  describe('when hash is not empty on load', () => {
    beforeEach(() => {
      window.location.hash = `#${DEFAULT_PROPS.panels[1].name}`;
      createComponent();
    });

    it('renders relevant container', () => {
      expect(wrapper.findComponent(WelcomePage).exists()).toBe(false);

      const container = wrapper.findComponent(LegacyContainer);

      expect(container.exists()).toBe(true);
      expect(container.props().selector).toBe(DEFAULT_PROPS.panels[1].selector);
    });

    it('renders breadcrumbs', () => {
      const breadcrumb = wrapper.findComponent(GlBreadcrumb);
      expect(breadcrumb.exists()).toBe(true);
      expect(breadcrumb.props().items[0].text).toBe(DEFAULT_PROPS.initialBreadcrumb);
    });
  });

  it('renders extra description if provided', () => {
    window.location.hash = `#${DEFAULT_PROPS.panels[1].name}`;
    const EXTRA_DESCRIPTION = 'Some extra description';
    createComponent({
      slots: {
        'extra-description': EXTRA_DESCRIPTION,
      },
    });

    expect(wrapper.text()).toContain(EXTRA_DESCRIPTION);
  });

  it('renders relevant container when hash changes', async () => {
    createComponent();
    expect(wrapper.findComponent(WelcomePage).exists()).toBe(true);

    window.location.hash = `#${DEFAULT_PROPS.panels[0].name}`;
    const ev = document.createEvent('HTMLEvents');
    ev.initEvent('hashchange', false, false);
    window.dispatchEvent(ev);

    await nextTick();
    expect(wrapper.findComponent(WelcomePage).exists()).toBe(false);
    expect(wrapper.findComponent(LegacyContainer).exists()).toBe(true);
  });
});
