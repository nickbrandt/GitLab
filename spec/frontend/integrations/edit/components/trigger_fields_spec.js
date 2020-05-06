import { mount } from '@vue/test-utils';
import TriggerFields from '~/integrations/edit/components/trigger_fields.vue';
import { GlFormGroup, GlFormCheckbox, GlFormInput } from '@gitlab/ui';

describe('TriggerFields', () => {
  let wrapper;

  const defaultProps = {
    type: 'slack',
  };

  const createComponent = props => {
    wrapper = mount(TriggerFields, {
      propsData: { ...defaultProps, ...props },
    });
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  const findAllGlFormCheckboxes = () => wrapper.findAll(GlFormCheckbox);
  const findAllGlFormInputs = () => wrapper.findAll(GlFormInput);

  describe('template', () => {
    it('renders a label with text "Trigger"', () => {
      createComponent();

      const triggerLabel = wrapper.find('label[for="trigger-fields"]');

      expect(triggerLabel.exists()).toBe(true);
      expect(triggerLabel.text()).toBe('Trigger');
    });

    describe('events without field property', () => {
      const events = [
        {
          title: 'push',
          name: 'push_event',
          description: 'Event on push',
          value: true,
        },
        {
          title: 'merge_request',
          name: 'merge_requests_event',
          description: 'Event on merge_request',
          value: false,
        },
      ];

      beforeEach(() => {
        createComponent({
          events,
        });
      });

      it('does not render GlFormInput for each event', () => {
        expect(findAllGlFormInputs().exists()).toBe(false);
      });

      it('renders GlFormInput with description for each event', () => {
        const groups = wrapper.find('#trigger-fields').findAll(GlFormGroup);

        expect(groups).toHaveLength(2);
        expect(
          groups
            .at(0)
            .find('small')
            .text(),
        ).toBe(events[0].description);
        expect(
          groups
            .at(1)
            .find('small')
            .text(),
        ).toBe(events[1].description);
      });

      it('renders GlFormCheckbox for each event', () => {
        const checkboxes = findAllGlFormCheckboxes();

        expect(checkboxes).toHaveLength(2);

        expect(
          checkboxes
            .at(0)
            .find('label')
            .text(),
        ).toBe('Push');
        expect(
          checkboxes
            .at(0)
            .find('input')
            .attributes('name'),
        ).toBe('service[push_event]');
        expect(checkboxes.at(0).vm.$attrs.checked).toBe(true);

        expect(
          checkboxes
            .at(1)
            .find('label')
            .text(),
        ).toBe('Merge Request');
        expect(
          checkboxes
            .at(1)
            .find('input')
            .attributes('name'),
        ).toBe('service[merge_requests_event]');
        expect(checkboxes.at(1).vm.$attrs.checked).toBe(false);
      });
    });

    describe('events with field property', () => {
      const events = [
        {
          field: {
            name: 'push_channel',
            value: '',
          },
        },
        {
          field: {
            name: 'merge_request_channel',
            value: 'gitlab-development',
          },
        },
      ];

      beforeEach(() => {
        createComponent({
          events,
        });
      });

      it('renders GlFormCheckbox for each event', () => {
        expect(findAllGlFormCheckboxes()).toHaveLength(2);
      });

      it('renders GlFormInput for each event', () => {
        const fields = findAllGlFormInputs();

        expect(fields).toHaveLength(2);

        expect(fields.at(0).attributes()).toMatchObject({
          name: 'service[push_channel]',
          placeholder: 'Slack channels (e.g. general, development)',
        });
        expect(fields.at(0).vm.$attrs.value).toBe('');

        expect(fields.at(1).attributes()).toMatchObject({
          name: 'service[merge_request_channel]',
          placeholder: 'Slack channels (e.g. general, development)',
        });
        expect(fields.at(1).vm.$attrs.value).toBe('gitlab-development');
      });
    });
  });
});
