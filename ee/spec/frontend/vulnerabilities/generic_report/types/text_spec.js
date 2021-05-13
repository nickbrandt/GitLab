import { shallowMount } from '@vue/test-utils';
import Text from 'ee/vulnerabilities/components/generic_report/types/text.vue';

describe('ee/vulnerabilities/components/generic_report/types/text.vue', () => {
  let wrapper;

  describe.each`
    field type   | value            | printValue
    ${'string'}  | ${'some string'} | ${'some string'}
    ${'number'}  | ${8}             | ${'8'}
    ${'boolean'} | ${true}          | ${'true'}
    ${'boolean'} | ${false}         | ${'false'}
  `('with data for $card', ({ fieldType, value, printValue }) => {
    const createWrapper = () => {
      return shallowMount(Text, {
        propsData: {
          type: 'text',
          name: `${fieldType} field`,
          value,
        },
      });
    };

    beforeEach(() => {
      wrapper = createWrapper();
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it(`renders ${fieldType} type`, () => {
      expect(wrapper.text()).toBe(printValue);
    });
  });
});
