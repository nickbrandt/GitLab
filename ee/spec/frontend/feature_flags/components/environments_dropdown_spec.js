import MockAdapter from 'axios-mock-adapter';
import { createLocalVue, mount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import EnvironmentsDropdown from 'ee/feature_flags/components/environments_dropdown.vue';
import { TEST_HOST } from 'spec/test_constants';

const localVue = createLocalVue();

describe('Feature flags > Environments dropdown ', () => {
  let wrapper;
  let mock;

  const factory = props => {
    wrapper = mount(localVue.extend(EnvironmentsDropdown), {
      localVue,
      propsData: {
        endpoint: `${TEST_HOST}/environments.json'`,
        ...props,
      },
      sync: false,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  describe('without value', () => {
    it('renders the placeholder', () => {
      factory();

      expect(wrapper.find('input').attributes('placeholder')).toEqual('Search an environment spec');
    });
  });

  describe('with value', () => {
    it('sets filter to equal the value', () => {
      factory({ value: 'production' });

      expect(wrapper.vm.filter).toEqual('production');
    });
  });

  describe('on input change', () => {
    const results = ['production', 'staging'];
    describe('on success', () => {
      beforeEach(() => {
        mock.onGet(`${TEST_HOST}/environments.json'`).replyOnce(200, results);

        factory();

        wrapper.find('input').setValue('production');
      });

      it('sets filter value', () => {
        expect(wrapper.vm.filter).toEqual('production');
      });

      describe('with received data', () => {
        beforeEach(done => setImmediate(() => done()));
        it('sets is loading to false', () => {
          expect(wrapper.vm.isLoading).toEqual(false);

          expect(wrapper.find(GlLoadingIcon).exists()).toEqual(false);
        });

        it('sets results with the received data', () => {
          expect(wrapper.vm.results).toEqual(results);
        });

        it('sets showSuggestions to true', () => {
          expect(wrapper.vm.showSuggestions).toEqual(true);
        });

        it('emits even when a suggestion is clicked', () => {
          jest.spyOn(wrapper.vm, '$emit');

          wrapper.find('ul button').trigger('click');

          expect(wrapper.vm.$emit).toHaveBeenCalledWith('selectEnvironment', 'production');
        });
      });
    });
  });

  describe('on click clear button', () => {
    beforeEach(() => {
      wrapper.find('.js-clear-search-input').trigger('click');
    });

    it('resets filter value', () => {
      expect(wrapper.vm.filter).toEqual('');
    });

    it('closes list of suggestions', () => {
      expect(wrapper.vm.showSuggestions).toEqual(false);
    });
  });

  describe('on click create button', () => {
    beforeEach(done => {
      mock.onGet(`${TEST_HOST}/environments.json'`).replyOnce(200, []);

      factory();

      wrapper.find('input').setValue('production');

      setImmediate(() => done());
    });

    it('emits create event', () => {
      jest.spyOn(wrapper.vm, '$emit');
      wrapper.find('.js-create-button').trigger('click');

      expect(wrapper.vm.$emit).toHaveBeenCalledWith('createClicked', 'production');
    });
  });
});
