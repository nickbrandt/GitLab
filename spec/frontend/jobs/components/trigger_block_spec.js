import { mount } from '@vue/test-utils';
import { GlButton, GlTable } from '@gitlab/ui';
import TriggerBlock from '~/jobs/components/trigger_block.vue';

describe('Trigger block', () => {
  let wrapper;

  const findRevealButton = () => wrapper.find(GlButton);
  const findVariableTable = () => wrapper.find(GlTable);
  const findShortToken = () => wrapper.find('[data-testid="trigger-short-token"]');
  const findVariableValue = (index) =>
    wrapper.findAll('[data-testid="trigger-build-value"]').at(index);
  const findVariableKey = (index) => wrapper.findAll('[data-testid="trigger-build-key"]').at(index);

  const createComponent = (props) => {
    wrapper = mount(TriggerBlock, {
      propsData: {
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('with short token', () => {
    it('renders short token', () => {
      createComponent({
        trigger: {
          short_token: '0a666b2',
          variables: [],
        },
      });

      expect(findShortToken().text()).toContain('0a666b2');
    });
  });

  describe('without variables or short token', () => {
    beforeEach(() => {
      createComponent({ trigger: { variables: [] } });
    });
    it('does not render short token', () => {
      expect(findShortToken().exists()).toBe(false);
    });

    it('does not render variables', () => {
      expect(findRevealButton().exists()).toBe(false);
      expect(findVariableTable().exists()).toBe(false);
    });
  });

  describe('with variables', () => {
    describe('hide/reveal variables', () => {
      it('should toggle variables on click', async () => {
        createComponent({
          trigger: {
            short_token: 'bd7e',
            variables: [
              { key: 'UPLOAD_TO_GCS', value: 'false', public: false },
              { key: 'UPLOAD_TO_S3', value: 'true', public: false },
            ],
          },
        });

        expect(findRevealButton().text()).toBe('Reveal values');

        expect(findVariableValue(0).text()).toBe('••••••');
        expect(findVariableValue(1).text()).toBe('••••••');

        expect(findVariableKey(0).text()).toBe('UPLOAD_TO_GCS');
        expect(findVariableKey(1).text()).toBe('UPLOAD_TO_S3');

        await findRevealButton().trigger('click');

        expect(findRevealButton().text()).toBe('Hide values');

        expect(findVariableValue(0).text()).toBe('false');
        expect(findVariableValue(1).text()).toBe('true');
      });
    });
  });
});
