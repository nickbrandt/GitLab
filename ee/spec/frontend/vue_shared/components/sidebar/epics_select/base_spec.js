import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';

import EpicsSelectBase from 'ee/vue_shared/components/sidebar/epics_select/base.vue';
import DropdownTitle from 'ee/vue_shared/components/sidebar/epics_select/dropdown_title.vue';
import DropdownValue from 'ee/vue_shared/components/sidebar/epics_select/dropdown_value.vue';
import DropdownValueCollapsed from 'ee/vue_shared/components/sidebar/epics_select/dropdown_value_collapsed.vue';

import DropdownButton from 'ee/vue_shared/components/sidebar/epics_select/dropdown_button.vue';
import DropdownHeader from 'ee/vue_shared/components/sidebar/epics_select/dropdown_header.vue';
import DropdownSearchInput from 'ee/vue_shared/components/sidebar/epics_select/dropdown_search_input.vue';
import DropdownContents from 'ee/vue_shared/components/sidebar/epics_select/dropdown_contents.vue';

import createDefaultStore from 'ee/vue_shared/components/sidebar/epics_select/store';

import { mockEpic1, mockEpic2, mockIssue, noneEpic } from '../mock_data';

describe('EpicsSelect', () => {
  describe('Base', () => {
    let wrapper;
    // const errorMessage = 'Something went wrong while fetching group epics.';
    const store = createDefaultStore();

    beforeEach(() => {
      setFixtures('<div class="flash-container"></div>');
      wrapper = shallowMount(EpicsSelectBase, {
        store,
        localVue: createLocalVue(),
        propsData: {
          canEdit: true,
          blockTitle: 'Epic',
          initialEpic: mockEpic1,
          initialEpicLoading: false,
          epicIssueId: mockIssue.epic_issue_id,
          groupId: mockEpic1.group_id,
          issueId: mockIssue.id,
        },
      });
    });

    afterEach(() => {
      wrapper.destroy();
    });

    describe('methods', () => {
      /*
      describe('fetchGroupEpics', () => {
        it('should call `service.getGroupEpics` and set response to store on request success', done => {
          jest.spyOn(wrapper.vm.service, 'getGroupEpics').mockResolvedValue({ data: mockEpics });
          jest.spyOn(wrapper.vm.store, 'setEpics');

          wrapper.vm
            .fetchGroupEpics()
            .then(() => {
              expect(wrapper.vm.isEpicsLoading).toBe(false);
              expect(wrapper.vm.store.setEpics).toHaveBeenCalledWith(mockEpics);
            })
            .then(done)
            .catch(done.fail);
        });

        it('should call `service.getGroupEpics` and show flash error on request failure', done => {
          jest.spyOn(wrapper.vm.service, 'getGroupEpics').mockRejectedValue();
          jest.spyOn(wrapper.vm.store, 'setEpics');

          wrapper.vm
            .fetchGroupEpics()
            .then(() => {
              expect(wrapper.vm.isEpicsLoading).toBe(false);
              expect(wrapper.vm.store.setEpics).not.toHaveBeenCalled();
              expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(
                errorMessage,
              );
            })
            .then(done)
            .catch(done.fail);
        });
      });

      describe('handleSelectSuccess', () => {
        const epic = { id: 15 };
        const issue = { id: 10 };

        it('should set selected Epic issue ID in store when `data.epic.id` & `data.issue.id` matches with seleced Epic ID & Issue ID respectively', done => {
          const mockData = {
            id: 22,
            epic,
            issue,
          };
          jest.spyOn(wrapper.vm.store, 'setSelectedEpicIssueId');

          wrapper.setProps({
            issueId: issue.id,
          });

          wrapper.vm.$nextTick(() => {
            wrapper.vm.handleSelectSuccess({
              data: mockData,
              epic,
              originalSelectedEpic: mockEpic1,
            });

            expect(wrapper.vm.isEpicSelectLoading).toBe(false);
            expect(wrapper.vm.store.setSelectedEpicIssueId).toHaveBeenCalledWith(mockData.id);
            done();
          });
        });

        it('should set revert to original Epic in store when `data.epic.id` & `data.issue.id` do not match with seleced Epic ID & Issue ID respectively', done => {
          const mockData = {
            id: 22,
            epic: { id: 11 },
            issue: { id: 17 },
          };

          jest.spyOn(wrapper.vm.store, 'setSelectedEpic');

          wrapper.setProps({
            issueId: issue.id,
          });

          wrapper.vm.$nextTick(() => {
            wrapper.vm.handleSelectSuccess({
              data: mockData,
              epic,
              originalSelectedEpic: mockEpic1,
            });

            expect(wrapper.vm.isEpicSelectLoading).toBe(false);
            expect(wrapper.vm.store.setSelectedEpic).toHaveBeenCalledWith(mockEpic1);
            done();
          });
        });
      });

      describe('handleSelectFailure', () => {
        it('should set originally selected epic back in the store', () => {
          jest.spyOn(wrapper.vm.store, 'setSelectedEpic');

          wrapper.vm.handleSelectFailure(errorMessage, mockEpic1);

          expect(wrapper.vm.isEpicSelectLoading).toBe(false);
          expect(wrapper.vm.store.setSelectedEpic).toHaveBeenCalledWith(mockEpic1);
        });

        it('should show flash error message', () => {
          wrapper.vm.handleSelectFailure(errorMessage, mockEpic1);

          expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(
            errorMessage,
          );
        });
      });

      describe('assignIssueToEpic', () => {
        it('should set `isEpicSelectLoading` to true while request is in progress', () => {
          jest
            .spyOn(wrapper.vm.service, 'assignIssueToEpic')
            .mockResolvedValue({ data: mockAssignRemoveRes });

          wrapper.vm.assignIssueToEpic(mockEpic1);

          expect(wrapper.vm.isEpicSelectLoading).toBe(true);
        });

        it('should set selected Epic to the store while request is in progress', () => {
          jest
            .spyOn(wrapper.vm.service, 'assignIssueToEpic')
            .mockResolvedValue({ data: mockAssignRemoveRes });
          jest.spyOn(wrapper.vm.store, 'setSelectedEpic');

          wrapper.vm.assignIssueToEpic(mockEpic1);

          expect(wrapper.vm.store.setSelectedEpic).toHaveBeenCalledWith(mockEpic1);
        });

        it('should set call `service.assignIssueToEpic` with `issueId` & `epic`', () => {
          jest
            .spyOn(wrapper.vm.service, 'assignIssueToEpic')
            .mockResolvedValue({ data: mockAssignRemoveRes });

          wrapper.vm.assignIssueToEpic(mockEpic1);

          expect(wrapper.vm.service.assignIssueToEpic).toHaveBeenCalledWith(
            mockIssue.id,
            mockEpic1,
          );
        });

        it('should set call `handleSelectSuccess` request response, epic and originally selected epic on request success', done => {
          jest
            .spyOn(wrapper.vm.service, 'assignIssueToEpic')
            .mockResolvedValue({ data: mockAssignRemoveRes });
          jest.spyOn(wrapper.vm, 'handleSelectSuccess');

          wrapper.vm
            .assignIssueToEpic(mockEpic1)
            .then(() => {
              expect(wrapper.vm.handleSelectSuccess).toHaveBeenCalledWith(
                expect.objectContaining({
                  data: mockAssignRemoveRes,
                  epic: mockEpic1,
                  originalSelectedEpic: mockEpic1,
                }),
              );
            })
            .then(done)
            .catch(done.fail);
        });

        it('should set call `handleSelectFailure` with error message and originally selected epic on request failure', done => {
          jest.spyOn(wrapper.vm.service, 'assignIssueToEpic').mockRejectedValue();
          jest.spyOn(wrapper.vm, 'handleSelectFailure');

          wrapper.vm
            .assignIssueToEpic(mockEpic1)
            .then(() => {
              expect(wrapper.vm.handleSelectFailure).toHaveBeenCalledWith(
                'Something went wrong while assigning issue to epic.',
                mockEpic1,
              );
            })
            .then(done)
            .catch(done.fail);
        });
      });

      describe('removeIssueFromEpic', () => {
        it('should set `isEpicSelectLoading` to true while request is in progress', () => {
          jest
            .spyOn(wrapper.vm.service, 'removeIssueFromEpic')
            .mockResolvedValue({ data: mockAssignRemoveRes });

          wrapper.vm.removeIssueFromEpic(mockEpic1);

          expect(wrapper.vm.isEpicSelectLoading).toBe(true);
        });

        it('should set `No Epic` to the store while request is in progress', () => {
          jest
            .spyOn(wrapper.vm.service, 'removeIssueFromEpic')
            .mockResolvedValue({ data: mockAssignRemoveRes });
          jest.spyOn(wrapper.vm.store, 'setSelectedEpic');

          wrapper.vm.removeIssueFromEpic(mockEpic1);

          expect(wrapper.vm.store.setSelectedEpic).toHaveBeenCalledWith(
            expect.objectContaining({
              ...noneEpic,
            }),
          );
        });

        it('should set call `service.removeIssueFromEpic` with selected `epicIssueId` & `epic`', () => {
          jest
            .spyOn(wrapper.vm.service, 'removeIssueFromEpic')
            .mockResolvedValue({ data: mockAssignRemoveRes });

          wrapper.vm.removeIssueFromEpic(mockEpic1);

          expect(wrapper.vm.service.removeIssueFromEpic).toHaveBeenCalledWith(
            mockIssue.epic_issue_id,
            mockEpic1,
          );
        });

        it('should set call `handleSelectSuccess` request response, epic and originally selected epic on request success', done => {
          jest
            .spyOn(wrapper.vm.service, 'removeIssueFromEpic')
            .mockResolvedValue({ data: mockAssignRemoveRes });
          jest.spyOn(wrapper.vm, 'handleSelectSuccess');

          wrapper.vm
            .removeIssueFromEpic(mockEpic1)
            .then(() => {
              expect(wrapper.vm.handleSelectSuccess).toHaveBeenCalledWith(
                expect.objectContaining({
                  data: mockAssignRemoveRes,
                  epic: mockEpic1,
                  originalSelectedEpic: mockEpic1,
                }),
              );
            })
            .then(done)
            .catch(done.fail);
        });

        it('should set call `handleSelectFailure` with error message and originally selected epic on request failure', done => {
          jest.spyOn(wrapper.vm.service, 'removeIssueFromEpic').mockRejectedValue();
          jest.spyOn(wrapper.vm, 'handleSelectFailure');

          wrapper.vm
            .removeIssueFromEpic(mockEpic1)
            .then(() => {
              expect(wrapper.vm.handleSelectFailure).toHaveBeenCalledWith(
                'Something went wrong while removing issue from epic.',
                mockEpic1,
              );
            })
            .then(done)
            .catch(done.fail);
        });
      });
      */

      describe('handleDropdownShown', () => {
        it('should call `fetchEpics` when `groupEpics` does not return any epics', done => {
          jest.spyOn(wrapper.vm, 'fetchEpics');

          store.dispatch('receiveEpicsSuccess', []);

          wrapper.vm.$nextTick(() => {
            wrapper.vm.handleDropdownShown();

            expect(wrapper.vm.fetchEpics).toHaveBeenCalled();

            done();
          });
        });
      });

      describe('handleDropdownHidden', () => {
        it('should set `showDropdown` to false', () => {
          wrapper.vm.handleDropdownHidden();

          expect(wrapper.vm.showDropdown).toBe(false);
        });
      });

      describe('handleItemSelect', () => {
        it('should call `removeIssueFromEpic` with selected epic when `epic` param represents `No Epic`', () => {
          jest.spyOn(wrapper.vm, 'removeIssueFromEpic');
          store.dispatch('setSelectedEpic', mockEpic1);

          wrapper.vm.handleItemSelect(noneEpic);

          expect(wrapper.vm.removeIssueFromEpic).toHaveBeenCalledWith(mockEpic1);
        });

        it('should call `assignIssueToEpic` with passed `epic` param when it does not represent `No Epic`', () => {
          jest.spyOn(wrapper.vm, 'assignIssueToEpic');

          wrapper.vm.handleItemSelect(mockEpic2);

          expect(wrapper.vm.assignIssueToEpic).toHaveBeenCalledWith(mockEpic2);
        });
      });
    });

    describe('template', () => {
      const showDropdown = () => {
        wrapper.setProps({
          canEdit: true,
        });
        wrapper.setData({
          showDropdown: true,
        });
      };

      it('should render component container element', () => {
        expect(wrapper.classes()).toContain('js-epic-block');
      });

      it('should render DropdownValueCollapsed component', () => {
        expect(wrapper.find(DropdownValueCollapsed).exists()).toBe(true);
      });

      it('should render DropdownTitle component', () => {
        expect(wrapper.find(DropdownTitle).exists()).toBe(true);
      });

      it('should render DropdownValue component when `showDropdown` is false', done => {
        wrapper.vm.showDropdown = false;

        wrapper.vm.$nextTick(() => {
          expect(wrapper.find(DropdownValue).exists()).toBe(true);
          done();
        });
      });

      it('should render dropdown container element when props `canEdit` & `showDropdown` are true', done => {
        showDropdown();

        wrapper.vm.$nextTick(() => {
          expect(wrapper.find('.epic-dropdown-container').exists()).toBe(true);
          expect(wrapper.find('.epic-dropdown-container .dropdown').exists()).toBe(true);
          done();
        });
      });

      it('should render DropdownButton component when props `canEdit` & `showDropdown` are true', done => {
        showDropdown();

        wrapper.vm.$nextTick(() => {
          expect(wrapper.find(DropdownButton).exists()).toBe(true);
          done();
        });
      });

      it('should render dropdown menu container element when props `canEdit` & `showDropdown` are true', done => {
        showDropdown();

        wrapper.vm.$nextTick(() => {
          expect(wrapper.find('.dropdown .dropdown-menu.dropdown-menu-epics').exists()).toBe(true);
          done();
        });
      });

      it('should render DropdownHeader component when props `canEdit` & `showDropdown` are true', done => {
        showDropdown();

        wrapper.vm.$nextTick(() => {
          expect(wrapper.find(DropdownHeader).exists()).toBe(true);
          done();
        });
      });

      it('should render DropdownSearchInput component when props `canEdit` & `showDropdown` are true', done => {
        showDropdown();

        wrapper.vm.$nextTick(() => {
          expect(wrapper.find(DropdownSearchInput).exists()).toBe(true);
          done();
        });
      });

      it('should render DropdownContents component when props `canEdit` & `showDropdown` are true and `isEpicsLoading` is false', done => {
        showDropdown();
        store.dispatch('receiveEpicsSuccess', []);

        wrapper.vm.$nextTick(() => {
          expect(wrapper.find(DropdownContents).exists()).toBe(true);
          done();
        });
      });

      it('should render GlLoadingIcon component when props `canEdit` & `showDropdown` and `isEpicsLoading` are true', done => {
        showDropdown();
        store.dispatch('requestEpics');

        wrapper.vm.$nextTick(() => {
          expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
          done();
        });
      });
    });
  });
});
