import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import AxiosMockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import Daterange from 'ee/analytics/productivity_analytics/components/daterange.vue';
import store from 'ee/analytics/productivity_analytics/store';
import { GlDaterangePicker } from '@gitlab/ui';
import resetStore from '../helpers';

const localVue = createLocalVue();
localVue.use(Vuex);

const startDate = new Date(2019, 8, 1);
const endDate = new Date(2019, 8, 11);
const groupNamespace = 'gitlab-org';

describe('Daterange component', () => {
  let wrapper;
  let axiosMock;

  const actionSpies = {
    setDateRange: jest.fn(),
  };

  const factory = (props = {}) => {
    wrapper = shallowMount(localVue.extend(Daterange), {
      localVue,
      store,
      sync: false,
      propsData: { ...props },
      methods: {
        ...actionSpies,
      },
    });
  };

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    axiosMock.onGet(store.state.endpoint).reply(200);
    jest.spyOn(global.Date, 'now').mockImplementation(() => new Date('2019-09-25T00:00:00Z'));
    factory();
  });

  afterEach(() => {
    wrapper.destroy();
    resetStore(store);
    axiosMock.restore();
  });

  const findDaterangePicker = () => wrapper.find(GlDaterangePicker);

  describe('template', () => {
    describe('when there is no groupNamespace set', () => {
      it('does not render the daterange picker', () => {
        expect(findDaterangePicker().exists()).toBe(false);
      });
    });

    describe('when a groupNamespace is set', () => {
      beforeEach(() => {
        store.state.filters.groupNamespace = groupNamespace;
      });

      it('renders the daterange picker', () => {
        expect(findDaterangePicker().exists()).toBe(true);
      });
    });
  });

  describe('mounted', () => {
    describe('initDateRange', () => {
      it('dispatches setDateRange with skipFetch=true', () => {
        expect(actionSpies.setDateRange).toHaveBeenCalledWith({
          skipFetch: true,
          startDate: new Date('2019-06-27T00:00:00.000Z'),
          endDate: new Date('2019-09-25T00:00:00.000Z'),
        });
      });
    });
  });

  describe('computed', () => {
    beforeEach(() => {
      store.state.filters.groupNamespace = groupNamespace;
    });

    describe('dateRange', () => {
      describe('set', () => {
        it('calls `setDateRange` with an object containing startDate and endDate', () => {
          wrapper.vm.dateRange = { startDate, endDate };

          expect(actionSpies.setDateRange).toHaveBeenCalledWith({ startDate, endDate });
        });
      });

      describe('get', () => {
        beforeEach(() => {
          store.state.filters.startDate = startDate;
          store.state.filters.endDate = endDate;
        });

        it("returns value of dateRange from state's startDate and endDate", () => {
          expect(wrapper.vm.dateRange).toEqual({ startDate, endDate });
        });
      });
    });
  });
});
