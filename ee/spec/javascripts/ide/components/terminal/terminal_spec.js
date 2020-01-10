import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
import Terminal from 'ee/ide/components/terminal/terminal.vue';
import TerminalControls from 'ee/ide/components/terminal/terminal_controls.vue';
import { STARTING, PENDING, RUNNING, STOPPING, STOPPED } from 'ee/ide/constants';

const TEST_TERMINAL_PATH = 'terminal/path';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('EE IDE Terminal', () => {
  let wrapper;
  let state;
  let GLTerminalSpy;

  const factory = propsData => {
    const store = new Vuex.Store({
      state,
      mutations: {
        set(prevState, newState) {
          Object.assign(prevState, newState);
        },
      },
    });

    wrapper = shallowMount(localVue.extend(Terminal), {
      propsData: {
        status: RUNNING,
        terminalPath: TEST_TERMINAL_PATH,
        ...propsData,
      },
      localVue,
      store,
    });
  };

  beforeEach(() => {
    GLTerminalSpy = spyOnDependency(Terminal, 'GLTerminal').and.returnValue(
      jasmine.createSpyObj('GLTerminal', [
        'dispose',
        'disable',
        'addScrollListener',
        'scrollToTop',
        'scrollToBottom',
      ]),
    );
    state = {
      panelResizing: false,
    };
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('loading text', () => {
    [STARTING, PENDING].forEach(status => {
      it(`shows when starting (${status})`, () => {
        factory({ status });

        expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
        expect(wrapper.find('.top-bar').text()).toBe('Starting...');
      });
    });

    it(`shows when stopping`, () => {
      factory({ status: STOPPING });

      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
      expect(wrapper.find('.top-bar').text()).toBe('Stopping...');
    });

    [RUNNING, STOPPED].forEach(status => {
      it('hides when not loading', () => {
        factory({ status });

        expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
        expect(wrapper.find('.top-bar').text()).toBe('');
      });
    });
  });

  describe('refs.terminal', () => {
    it('has terminal path in data', () => {
      factory();

      expect(wrapper.vm.$refs.terminal.dataset.projectPath).toBe(TEST_TERMINAL_PATH);
    });
  });

  describe('terminal controls', () => {
    beforeEach(done => {
      factory();
      wrapper.vm.createTerminal();
      localVue.nextTick(done);
    });

    it('is visible if terminal is created', () => {
      expect(wrapper.find(TerminalControls).exists()).toBe(true);
    });

    it('scrolls glterminal on scroll-up', () => {
      wrapper.find(TerminalControls).vm.$emit('scroll-up');

      expect(wrapper.vm.glterminal.scrollToTop).toHaveBeenCalled();
    });

    it('scrolls glterminal on scroll-down', () => {
      wrapper.find(TerminalControls).vm.$emit('scroll-down');

      expect(wrapper.vm.glterminal.scrollToBottom).toHaveBeenCalled();
    });

    it('has props set', done => {
      expect(wrapper.find(TerminalControls).props()).toEqual({
        canScrollUp: false,
        canScrollDown: false,
      });

      wrapper.setData({ canScrollUp: true, canScrollDown: true });

      localVue
        .nextTick()
        .then(() => {
          expect(wrapper.find(TerminalControls).props()).toEqual({
            canScrollUp: true,
            canScrollDown: true,
          });
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('refresh', () => {
    let createTerminal;
    let stopTerminal;

    beforeEach(() => {
      createTerminal = jasmine.createSpy('createTerminal');
      stopTerminal = jasmine.createSpy('stopTerminal');
    });

    it('creates the terminal if running', () => {
      factory({ status: RUNNING, terminalPath: TEST_TERMINAL_PATH });

      wrapper.setMethods({ createTerminal });
      wrapper.vm.refresh();

      expect(createTerminal).toHaveBeenCalled();
    });

    it('stops the terminal if stopping', () => {
      factory({ status: STOPPING });

      wrapper.setMethods({ stopTerminal });
      wrapper.vm.refresh();

      expect(stopTerminal).toHaveBeenCalled();
    });
  });

  describe('createTerminal', () => {
    beforeEach(() => {
      factory();
      wrapper.vm.createTerminal();
    });

    it('creates the terminal', () => {
      expect(GLTerminalSpy).toHaveBeenCalledWith(wrapper.vm.$refs.terminal);
      expect(wrapper.vm.glterminal).toBeTruthy();
    });

    describe('scroll listener', () => {
      it('has been called', () => {
        expect(wrapper.vm.glterminal.addScrollListener).toHaveBeenCalled();
      });

      it('updates scroll data when called', () => {
        expect(wrapper.vm.canScrollUp).toBe(false);
        expect(wrapper.vm.canScrollDown).toBe(false);

        const listener = wrapper.vm.glterminal.addScrollListener.calls.argsFor(0)[0];
        listener({ canScrollUp: true, canScrollDown: true });

        expect(wrapper.vm.canScrollUp).toBe(true);
        expect(wrapper.vm.canScrollDown).toBe(true);
      });
    });
  });

  describe('destroyTerminal', () => {
    it('calls dispose', () => {
      factory();
      wrapper.vm.createTerminal();
      const disposeSpy = wrapper.vm.glterminal.dispose;

      expect(disposeSpy).not.toHaveBeenCalled();

      wrapper.vm.destroyTerminal();

      expect(disposeSpy).toHaveBeenCalled();
      expect(wrapper.vm.glterminal).toBe(null);
    });
  });

  describe('stopTerminal', () => {
    it('calls disable', () => {
      factory();
      wrapper.vm.createTerminal();

      expect(wrapper.vm.glterminal.disable).not.toHaveBeenCalled();

      wrapper.vm.stopTerminal();

      expect(wrapper.vm.glterminal.disable).toHaveBeenCalled();
    });
  });
});
