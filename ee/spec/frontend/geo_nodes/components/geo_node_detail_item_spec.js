import { shallowMount } from '@vue/test-utils';

import StackedProgressBar from '~/vue_shared/components/stacked_progress_bar.vue';
import GeoNodeDetailItemComponent from 'ee/geo_nodes/components/geo_node_detail_item.vue';
import GeoNodeSyncSettings from 'ee/geo_nodes/components/geo_node_sync_settings.vue';
import GeoNodeEventStatus from 'ee/geo_nodes/components/geo_node_event_status.vue';

import { VALUE_TYPE, CUSTOM_TYPE } from 'ee/geo_nodes/constants';
import { rawMockNodeDetails } from '../mock_data';

describe('GeoNodeDetailItemComponent', () => {
  let wrapper;

  const defaultProps = {
    itemTitle: 'GitLab version',
    cssClass: 'node-version',
    itemValue: '10.4.0-pre',
    successLabel: 'Synced',
    failureLabel: 'Failed',
    neutralLabel: 'Out of sync',
    itemValueType: VALUE_TYPE.PLAIN,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(GeoNodeDetailItemComponent, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders container elements correctly', () => {
      expect(wrapper.vm.$el.classList.contains('node-detail-item')).toBeTruthy();
      expect(wrapper.vm.$el.querySelectorAll('.node-detail-title').length).not.toBe(0);
      expect(wrapper.vm.$el.querySelector('.node-detail-title').innerText.trim()).toBe(
        'GitLab version',
      );
    });

    it('renders plain item value', () => {
      expect(wrapper.vm.$el.querySelectorAll('.node-detail-value').length).not.toBe(0);
      expect(wrapper.vm.$el.querySelector('.node-detail-value').innerText.trim()).toBe(
        '10.4.0-pre',
      );
    });

    describe('when graph item value', () => {
      beforeEach(() => {
        createComponent({
          itemValueType: VALUE_TYPE.GRAPH,
          itemValue: { successCount: 5, failureCount: 3, totalCount: 10 },
        });
      });

      it('renders progress bar', () => {
        expect(wrapper.find(StackedProgressBar).exists()).toBeTruthy();
      });

      describe('with itemValueStale prop', () => {
        const itemValueStaleTooltip = 'Data is out of date from 8 hours ago';

        beforeEach(() => {
          createComponent({
            itemValueType: VALUE_TYPE.GRAPH,
            itemValue: { successCount: 5, failureCount: 3, totalCount: 10 },
            itemValueStale: true,
            itemValueStaleTooltip,
          });
        });

        it('renders stale information icon', () => {
          const iconEl = wrapper.find('.text-warning-500');

          expect(iconEl).not.toBeNull();
          expect(iconEl.attributes('data-original-title')).toBe(itemValueStaleTooltip);
          expect(iconEl.attributes('name')).toBe('time-out');
        });
      });
    });

    describe('when custom type is sync', () => {
      beforeEach(() => {
        createComponent({
          itemValueType: VALUE_TYPE.CUSTOM,
          customType: CUSTOM_TYPE.SYNC,
          itemValue: {
            namespaces: rawMockNodeDetails.namespaces,
            lastEvent: {
              id: rawMockNodeDetails.last_event_id,
              timeStamp: rawMockNodeDetails.last_event_timestamp,
            },
            cursorLastEvent: {
              id: rawMockNodeDetails.cursor_last_event_id,
              timeStamp: rawMockNodeDetails.cursor_last_event_timestamp,
            },
          },
        });
      });

      it('renders sync settings item value', () => {
        expect(wrapper.find(GeoNodeSyncSettings).exists()).toBeTruthy();
      });
    });

    describe('when custom type is event', () => {
      beforeEach(() => {
        createComponent({
          itemValueType: VALUE_TYPE.CUSTOM,
          customType: CUSTOM_TYPE.EVENT,
          itemValue: {
            eventId: rawMockNodeDetails.last_event_id,
            eventTimeStamp: rawMockNodeDetails.last_event_timestamp,
          },
        });
      });

      it('renders event status item value', () => {
        expect(wrapper.find(GeoNodeEventStatus).exists()).toBeTruthy();
      });
    });

    describe('when featureDisabled is true', () => {
      beforeEach(() => {
        createComponent({
          featureDisabled: true,
        });
      });

      it('does not render', () => {
        expect(wrapper.vm.$el.innerHTML).toBeUndefined();
      });
    });
  });
});
