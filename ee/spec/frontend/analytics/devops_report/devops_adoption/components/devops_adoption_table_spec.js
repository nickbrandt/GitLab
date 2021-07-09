import { GlTable, GlButton, GlIcon, GlBadge } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import DevopsAdoptionDeleteModal from 'ee/analytics/devops_report/devops_adoption/components/devops_adoption_delete_modal.vue';
import DevopsAdoptionTable from 'ee/analytics/devops_report/devops_adoption/components/devops_adoption_table.vue';
import DevopsAdoptionTableCellFlag from 'ee/analytics/devops_report/devops_adoption/components/devops_adoption_table_cell_flag.vue';
import {
  DEVOPS_ADOPTION_TABLE_TEST_IDS as TEST_IDS,
  DEVOPS_ADOPTION_TABLE_CONFIGURATION,
} from 'ee/analytics/devops_report/devops_adoption/constants';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import { devopsAdoptionNamespaceData, devopsAdoptionTableHeaders } from '../mock_data';

describe('DevopsAdoptionTable', () => {
  let wrapper;

  const createComponent = (options = {}) => {
    const { provide = {} } = options;

    wrapper = mount(DevopsAdoptionTable, {
      propsData: {
        cols: DEVOPS_ADOPTION_TABLE_CONFIGURATION[0].cols,
        enabledNamespaces: devopsAdoptionNamespaceData.nodes,
      },
      provide,
      directives: {
        GlTooltip: createMockDirective(),
      },
    });
  };

  beforeEach(() => {
    localStorage.clear();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const findTable = () => wrapper.find(GlTable);

  const findCol = (testId) => findTable().find(`[data-testid="${testId}"]`);

  const findColRowChild = (col, row, child) =>
    findTable().findAll(`[data-testid="${col}"]`).at(row).find(child);

  const findColSubComponent = (colTestId, childComponent) =>
    findCol(colTestId).find(childComponent);

  const findSortByLocalStorageSync = () => wrapper.findAll(LocalStorageSync).at(0);
  const findSortDescLocalStorageSync = () => wrapper.findAll(LocalStorageSync).at(1);

  const findDeleteModal = () => wrapper.find(DevopsAdoptionDeleteModal);

  describe('table headings', () => {
    let headers;

    beforeEach(() => {
      createComponent();
      headers = findTable().findAll(`[data-testid="${TEST_IDS.TABLE_HEADERS}"]`);
    });

    it('displays the correct number of headings', () => {
      expect(headers).toHaveLength(devopsAdoptionTableHeaders.length);
    });

    describe.each(devopsAdoptionTableHeaders)(
      'header fields',
      ({ label, tooltip: tooltipText, index }) => {
        let headerWrapper;

        beforeEach(() => {
          headerWrapper = headers.at(index);
        });

        it(`displays the correct table heading text for "${label}"`, () => {
          expect(headerWrapper.text()).toContain(label);
        });

        describe(`helper information for "${label}"`, () => {
          const expected = Boolean(tooltipText);

          it(`${expected ? 'displays' : "doesn't display"} an information icon`, () => {
            expect(headerWrapper.find(GlIcon).exists()).toBe(expected);
          });

          if (expected) {
            it('includes a tooltip', () => {
              const icon = headerWrapper.find(GlIcon);
              const tooltip = getBinding(icon.element, 'gl-tooltip');

              expect(tooltip).toBeDefined();
              expect(tooltip.value).toBe(tooltipText);
            });
          }
        });
      },
    );
  });

  describe('table fields', () => {
    describe('enabled namespace name', () => {
      beforeEach(() => {
        createComponent();
      });

      it('displays the correct name', () => {
        createComponent();

        expect(findCol(TEST_IDS.NAMESPACE).text()).toBe('Group 1');
      });

      describe('"This group" badge', () => {
        const thisGroupGid = devopsAdoptionNamespaceData.nodes[0].namespace.id;

        it.each`
          scenario                            | expected | provide
          ${'is not shown by default'}        | ${false} | ${null}
          ${'is not shown for other groups'}  | ${false} | ${{ groupGid: 'anotherGroupGid' }}
          ${'is shown for the current group'} | ${true}  | ${{ groupGid: thisGroupGid }}
        `('$scenario', ({ expected, provide }) => {
          createComponent({ provide });

          const badge = findColSubComponent(TEST_IDS.NAMESPACE, GlBadge);

          expect(badge.exists()).toBe(expected);
        });
      });

      describe('pending state (no snapshot data available)', () => {
        beforeEach(() => {
          createComponent();
        });

        it('grays the text out', () => {
          const name = findColRowChild(TEST_IDS.NAMESPACE, 1, 'span');

          expect(name.classes()).toStrictEqual(['gl-text-gray-400']);
        });

        describe('hourglass icon', () => {
          let icon;

          beforeEach(() => {
            icon = findColRowChild(TEST_IDS.NAMESPACE, 1, GlIcon);
          });

          it('displays the icon', () => {
            expect(icon.exists()).toBe(true);
            expect(icon.props('name')).toBe('hourglass');
          });
        });
      });
    });

    const testCols = DEVOPS_ADOPTION_TABLE_CONFIGURATION[0].cols.map((col) => [col.label, col]);

    it.each(testCols)('displays the cell flag component for %s', (label, { testId }) => {
      createComponent();

      const booleanFlag = findColSubComponent(testId, DevopsAdoptionTableCellFlag);

      expect(booleanFlag.exists()).toBe(true);
    });

    describe.each`
      scenario              | tooltipText                                            | provide                                                            | disabled
      ${'not active group'} | ${'Remove Group from the table.'}                      | ${{}}                                                              | ${false}
      ${'active group'}     | ${'You cannot remove the group you are currently in.'} | ${{ groupGid: devopsAdoptionNamespaceData.nodes[0].namespace.id }} | ${true}
    `('actions column when $scenario', ({ tooltipText, provide, disabled }) => {
      beforeEach(() => {
        createComponent({ provide });
      });

      it('displays the actions icon', () => {
        const button = findColSubComponent(TEST_IDS.ACTIONS, GlButton);

        expect(button.exists()).toBe(true);
        expect(button.props('disabled')).toBe(disabled);
        expect(button.props('icon')).toBe('remove');
        expect(button.props('category')).toBe('tertiary');
      });

      it('wraps the icon in an element with a tooltip', () => {
        const iconWrapper = findCol(TEST_IDS.ACTIONS);
        const tooltip = getBinding(iconWrapper.element, 'gl-tooltip');

        expect(iconWrapper.exists()).toBe(true);
        expect(tooltip).toBeDefined();
        expect(tooltip.value).toBe(tooltipText);
      });
    });
  });

  describe('delete modal integration', () => {
    beforeEach(() => {
      createComponent();

      wrapper.setData({
        selectedNamespace: devopsAdoptionNamespaceData.nodes[0],
      });
    });

    it('re emits trackModalOpenState with the given value', async () => {
      findDeleteModal().vm.$emit('trackModalOpenState', true);

      expect(wrapper.emitted('trackModalOpenState')).toStrictEqual([[true]]);
    });
  });

  describe('sorting', () => {
    let headers;

    beforeEach(() => {
      createComponent();
      headers = findTable().findAll(`[data-testid="${TEST_IDS.TABLE_HEADERS}"]`);
    });

    it('sorts the namespaces by name', async () => {
      expect(findCol(TEST_IDS.NAMESPACE).text()).toBe('Group 1');

      headers.at(0).trigger('click');

      await nextTick();

      expect(findCol(TEST_IDS.NAMESPACE).text()).toBe('Group 2');
    });

    it('should update local storage when the sort column changes', async () => {
      expect(findSortByLocalStorageSync().props('value')).toBe('name');

      headers.at(1).trigger('click');

      await nextTick();

      expect(findSortByLocalStorageSync().props('value')).toBe('mergeRequestApproved');
    });

    it('should update local storage when the sort direction changes', async () => {
      expect(findSortDescLocalStorageSync().props('value')).toBe(false);

      headers.at(0).trigger('click');

      await nextTick();

      expect(findSortDescLocalStorageSync().props('value')).toBe(true);
    });
  });
});
