import { mount } from '@vue/test-utils';
import AnalyzerConfiguration from 'ee/security_configuration/sast/components/analyzer_configuration.vue';
import DynamicFields from 'ee/security_configuration/sast/components/dynamic_fields.vue';

describe('AnalyzerConfiguration component', () => {
  let wrapper;

  const entity = {
    name: 'name',
    label: 'label',
    description: 'description',
    enabled: false,
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = mount(AnalyzerConfiguration, {
      propsData: {
        ...props,
      },
    });
  };

  const findInputElement = () => wrapper.find('input[type="checkbox"]');
  const findDynamicFields = () => wrapper.find(DynamicFields);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('label', () => {
    beforeEach(() => {
      createComponent({
        props: { entity },
      });
    });

    it('renders the label', () => {
      expect(wrapper.text()).toContain(entity.label);
    });

    it('renders the description', () => {
      expect(wrapper.text()).toContain(entity.description);
    });
  });

  describe.each`
    initiallyChecked
    ${false}
    ${true}
  `('with checkbox initially checked $initiallyChecked ', ({ initiallyChecked }) => {
    beforeEach(() => {
      createComponent({
        props: { entity: { ...entity, enabled: initiallyChecked } },
      });
    });

    it('sets the checkbox input to the correct checked state', () => {
      expect(findInputElement().element.checked).toBe(initiallyChecked);
    });

    describe('when the user checks the checkbox', () => {
      beforeEach(() => {
        findInputElement().setChecked(!initiallyChecked);
      });

      it('emits a input event with the checked value', () => {
        expect(wrapper.emitted('input')).toEqual([[{ ...entity, enabled: !initiallyChecked }]]);
      });
    });
  });

  describe('configuration form', () => {
    describe('when there are no SastCiConfigurationEntity', () => {
      beforeEach(() => {
        createComponent({
          props: { entity },
        });
      });

      it('does not render the nested dynamic forms', () => {
        expect(findDynamicFields().exists()).toBe(false);
      });
    });

    describe('when there are one or more SastCiConfigurationEntity', () => {
      const analyzerEntity = {
        ...entity,
        enabled: false,
        configuration: [
          {
            defaultValue: 'defaultVal',
            description: 'desc',
            field: 'field',
            type: 'string',
            value: 'val',
            label: 'label',
          },
        ],
      };

      beforeEach(() => {
        createComponent({
          props: { entity: analyzerEntity },
        });
      });

      it('it renders the nested dynamic forms', () => {
        expect(findDynamicFields().exists()).toBe(true);
      });

      it('it emits an input event when dynamic form fields emits an input event', () => {
        findDynamicFields().vm.$emit('input', analyzerEntity.configuration);

        const [[payload]] = wrapper.emitted('input');
        expect(payload).toEqual(analyzerEntity);
      });

      it('passes the disabled prop to dynamic fields component', () => {
        expect(findDynamicFields().vm.$attrs.disabled).toBe(!analyzerEntity.enabled);
      });

      it('passes the entities prop to the dynamic fields component', () => {
        expect(findDynamicFields().props('entities')).toBe(analyzerEntity.configuration);
      });
    });
  });
});
