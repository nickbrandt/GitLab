import { nextTick } from 'vue';
import { mount } from '@vue/test-utils';
import { GlToken, GlTokenSelector } from '@gitlab/ui';

import CommaSeparatedListTokenSelector from 'ee/groups/settings/components/comma_separated_list_token_selector.vue';

describe('CommaSeparatedListTokenSelector', () => {
  let wrapper;
  let div;
  let input;

  const defaultProps = {
    hiddenInputId: 'comma-separated-list',
    ariaLabelledby: 'comma-separated-list-label',
  };

  const createComponent = options => {
    wrapper = mount(CommaSeparatedListTokenSelector, {
      attachTo: div,
      ...options,
      propsData: {
        ...defaultProps,
        ...(options?.propsData || {}),
      },
    });
  };

  beforeEach(() => {
    div = document.createElement('div');
    input = document.createElement('input');
    input.setAttribute('type', 'text');
    input.id = 'comma-separated-list';
    document.body.appendChild(div);
    div.appendChild(input);
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    div.remove();
  });

  describe('when component is mounted', () => {
    it.each`
      inputValue                                 | expectedTokens
      ${'gitlab.com,gitlab.org,gitlab.ninja'}    | ${['gitlab.com', 'gitlab.org', 'gitlab.ninja']}
      ${'gitlab.com, gitlab.org,  gitlab.ninja'} | ${['gitlab.com', 'gitlab.org', 'gitlab.ninja']}
      ${'foo bar, baz'}                          | ${['foo bar', 'baz']}
      ${'192.168.0.0/24,192.168.1.0/24'}         | ${['192.168.0.0/24', '192.168.1.0/24']}
    `(
      'parses comma separated list ($inputValue) into tokens',
      async ({ inputValue, expectedTokens }) => {
        input.value = inputValue;
        createComponent();

        await nextTick();

        wrapper.findAll(GlToken).wrappers.forEach((tokenWrapper, index) => {
          expect(tokenWrapper.text()).toBe(expectedTokens[index]);
        });
      },
    );
  });

  describe('when selected tokens changes', () => {
    const setup = async () => {
      const tokens = [
        {
          id: 1,
          name: 'gitlab.com',
        },
        {
          id: 2,
          name: 'gitlab.org',
        },
        {
          id: 3,
          name: 'gitlab.ninja',
        },
      ];

      createComponent();

      await wrapper.setData({
        selectedTokens: tokens,
      });
    };

    it('sets input value ', async () => {
      await setup();

      expect(input.value).toBe('gitlab.com,gitlab.org,gitlab.ninja');
    });

    it('fires `input` event', async () => {
      const dispatchEvent = jest.spyOn(input, 'dispatchEvent');
      await setup();

      expect(dispatchEvent).toHaveBeenCalledWith(
        new Event('input', {
          bubbles: true,
          cancelable: true,
        }),
      );
    });
  });

  describe('when enter key is pressed', () => {
    it('does not submit the form if token selector text input has a value', async () => {
      createComponent();

      const tokenSelectorInput = wrapper.find(GlTokenSelector).find('input[type="text"]');
      tokenSelectorInput.element.value = 'foo bar';

      const event = { preventDefault: jest.fn() };
      await tokenSelectorInput.trigger('keydown.enter', event);

      expect(event.preventDefault).toHaveBeenCalled();
    });
  });
});
