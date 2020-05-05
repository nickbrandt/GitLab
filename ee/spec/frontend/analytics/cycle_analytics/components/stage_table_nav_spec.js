import { mount, shallowMount } from '@vue/test-utils';
import StageTableNav from 'ee/analytics/cycle_analytics/components/stage_table_nav.vue';
import StageNavItem from 'ee/analytics/cycle_analytics/components/stage_nav_item.vue';
import AddStageButton from 'ee/analytics/cycle_analytics/components/add_stage_button.vue';
import { issueStage, allowedStages as stages, stageMedians as medians } from '../mock_data';

describe('StageTableNav', () => {
  function createComponent({ props = {}, mountFn = shallowMount } = {}) {
    return mountFn(StageTableNav, {
      propsData: {
        currentStage: issueStage,
        medians,
        stages,
        isCreatingCustomStage: false,
        customStageFormActive: false,
        canEditStages: false,
        customOrdering: false,
        errorSavingStageOrder: false,
        ...props,
      },
    });
  }

  let wrapper = null;

  afterEach(() => {
    wrapper.destroy();
  });

  function selectStage(index) {
    wrapper
      .findAll(StageNavItem)
      .at(index)
      .trigger('click');
  }

  describe('when a stage is clicked', () => {
    beforeEach(() => {
      wrapper = createComponent({ mountFn: mount });
    });

    it('will emit `selectStage`', () => {
      expect(wrapper.emitted('selectStage')).toBeUndefined();

      selectStage(1);

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted().selectStage.length).toEqual(1);
      });
    });

    it('will emit `selectStage` with the new stage title', () => {
      const secondStage = stages[1];

      selectStage(1);

      return wrapper.vm.$nextTick().then(() => {
        const [params] = wrapper.emitted('selectStage')[0];
        expect(params).toMatchObject({ title: secondStage.title });
      });
    });
  });

  describe('canEditStages = true', () => {
    beforeEach(() => {
      wrapper = createComponent({
        props: {
          canEditStages: true,
        },
      });
    });

    afterEach(() => {
      wrapper.destroy();
    });
    it('will render the add a stage button', () => {
      expect(wrapper.find(AddStageButton).exists()).toBe(true);
    });
  });

  describe.each`
    flag                       | value
    ${'customOrdering'}        | ${true}
    ${'customOrdering'}        | ${false}
    ${'errorSavingStageOrder'} | ${false}
  `('Manual ordering', ({ flag, value }) => {
    const result = value ? 'enabled' : 'disabled';

    beforeEach(() => {
      wrapper = createComponent({
        props: {
          [flag]: value,
        },
      });
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it(`with ${flag} = ${value} manual ordering is ${result}`, () => {
      expect(wrapper.find('.js-manual-ordering').exists()).toBe(value);
    });
  });
});
