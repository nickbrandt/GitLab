import { shallowMount } from '@vue/test-utils';
import GeoNodeFormCore from 'ee/geo_node_form/components/geo_node_form_core.vue';
import { MOCK_NODE, STRING_OVER_255 } from '../mock_data';

describe('GeoNodeFormCore', () => {
  let wrapper;

  const defaultProps = {
    nodeData: MOCK_NODE,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(GeoNodeFormCore, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGeoNodeFormNameField = () => wrapper.find('#node-name-field');
  const findGeoNodeFormUrlField = () => wrapper.find('#node-url-field');

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders Geo Node Form Name Field', () => {
      expect(findGeoNodeFormNameField().exists()).toBe(true);
    });

    it('renders Geo Node Form Url Field', () => {
      expect(findGeoNodeFormUrlField().exists()).toBe(true);
    });
  });

  describe('computed', () => {
    describe.each`
      data               | dataDesc            | blur     | value
      ${''}              | ${'empty'}          | ${false} | ${true}
      ${''}              | ${'empty'}          | ${true}  | ${false}
      ${STRING_OVER_255} | ${'over 255 chars'} | ${false} | ${true}
      ${STRING_OVER_255} | ${'over 255 chars'} | ${true}  | ${false}
      ${'Test'}          | ${'valid'}          | ${false} | ${true}
      ${'Test'}          | ${'valid'}          | ${true}  | ${true}
    `(`validName`, ({ data, dataDesc, blur, value }) => {
      beforeEach(() => {
        createComponent({
          nodeData: { ...defaultProps.nodeData, name: data },
        });
      });

      describe(`when data is: ${dataDesc}`, () => {
        it(`returns ${value} when blur is ${blur}`, () => {
          wrapper.vm.fieldBlurs.name = blur;

          expect(wrapper.vm.validName).toBe(value);
        });
      });
    });

    describe.each`
      data                    | dataDesc         | blur     | value
      ${''}                   | ${'empty'}       | ${false} | ${true}
      ${''}                   | ${'empty'}       | ${true}  | ${false}
      ${'abcd'}               | ${'invalid url'} | ${false} | ${true}
      ${'abcd'}               | ${'invalid url'} | ${true}  | ${false}
      ${'https://gitlab.com'} | ${'valid url'}   | ${false} | ${true}
      ${'https://gitlab.com'} | ${'valid url'}   | ${true}  | ${true}
    `(`validUrl`, ({ data, dataDesc, blur, value }) => {
      beforeEach(() => {
        createComponent({
          nodeData: { ...defaultProps.nodeData, url: data },
        });
      });

      describe(`when data is: ${dataDesc}`, () => {
        it(`returns ${value} when blur is ${blur}`, () => {
          wrapper.vm.fieldBlurs.url = blur;

          expect(wrapper.vm.validUrl).toBe(value);
        });
      });
    });
  });

  describe('methods', () => {
    describe('blur', () => {
      beforeEach(() => {
        createComponent();
      });

      it('sets fieldBlur[field] to true', () => {
        expect(wrapper.vm.fieldBlurs.name).toBeFalsy();
        wrapper.vm.blur('name');
        expect(wrapper.vm.fieldBlurs.name).toBeTruthy();
      });
    });
  });
});
