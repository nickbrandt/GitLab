import { shallowMount, mount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import StageTable from 'ee/analytics/cycle_analytics/components/stage_table.vue';
import { issueEvents, issueStage, allowedStages } from '../mock_data';

let wrapper = null;
const $sel = {
  nav: '.stage-nav',
  eventList: '.stage-events',
  events: '.stage-event-item',
  description: '.events-description',
  headers: '.col-headers li',
  headersList: '.col-headers',
  illustration: '.empty-state .svg-content',
};

const headers = ['Stage', 'Median', issueStage.legend, 'Time'];
const noDataSvgPath = 'path/to/no/data';

const StageTableNavSlot = {
  name: 'stage-table-nav-slot-stub',
  template: '<ul><li v-for="stage in stages">{{ stage.title }}</li></ul>',
};

function createComponent(props = {}, shallow = false) {
  const func = shallow ? shallowMount : mount;
  return func(StageTable, {
    propsData: {
      currentStage: issueStage,
      isLoading: false,
      isEmptyStage: false,
      currentStageEvents: issueEvents,
      noDataSvgPath,
      customStageFormActive: false,
      ...props,
    },
    slots: {
      nav: StageTableNavSlot,
    },
    mocks: {
      stages: allowedStages,
    },
    stubs: {
      'stage-nav-item': true,
      'gl-loading-icon': true,
    },
  });
}

describe('StageTable', () => {
  describe('headers', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('will render the headers', () => {
      const renderedHeaders = wrapper.findAll($sel.headers);
      expect(renderedHeaders).toHaveLength(headers.length);

      const headerText = wrapper.find($sel.headersList).text();
      headers.forEach(title => {
        expect(headerText).toContain(title);
      });
    });
  });

  describe('is loaded with data', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('will render the events list', () => {
      expect(wrapper.find($sel.eventList).exists()).toBeTruthy();
    });

    it('will render the correct stages', () => {
      const evs = wrapper.find(StageTableNavSlot).findAll('li');
      expect(evs).toHaveLength(allowedStages.length);

      const nav = wrapper.find($sel.nav).html();
      allowedStages.forEach(stage => {
        expect(nav).toContain(stage.title);
      });
    });

    it('will render the current stage', () => {
      expect(wrapper.find($sel.description).exists()).toBeTruthy();
      expect(wrapper.find($sel.description).text()).toEqual(issueStage.description);
    });

    it('will render the event list', () => {
      expect(wrapper.find($sel.eventList).exists()).toBeTruthy();
      expect(wrapper.findAll($sel.events).exists()).toBeTruthy();
    });

    it('will render the correct events', () => {
      const evs = wrapper.findAll($sel.events);
      expect(evs).toHaveLength(issueEvents.length);

      const evshtml = wrapper.find($sel.eventList).html();
      issueEvents.forEach(ev => {
        expect(evshtml).toContain(ev.title);
      });
    });
  });

  it('isLoading = true', () => {
    wrapper = createComponent({ isLoading: true }, true);
    expect(wrapper.find(GlLoadingIcon).exists()).toEqual(true);
  });

  describe('isEmptyStage = true', () => {
    beforeEach(() => {
      wrapper = createComponent({ isEmptyStage: true });
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('will render the empty stage illustration', () => {
      expect(wrapper.find($sel.illustration).exists()).toBeTruthy();
      expect(wrapper.find($sel.illustration).html()).toContain(noDataSvgPath);
    });

    it('will display the no data message', () => {
      expect(wrapper.html()).toContain("We don't have enough data to show this stage.");
    });
  });
});
