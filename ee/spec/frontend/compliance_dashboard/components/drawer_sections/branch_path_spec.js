import { shallowMount } from '@vue/test-utils';
import BranchPath from 'ee/compliance_dashboard/components/drawer_sections/branch_path.vue';
import BranchDetails from 'ee/compliance_dashboard/components/shared/branch_details.vue';
import DrawerSectionHeader from 'ee/compliance_dashboard/components/shared/drawer_section_header.vue';

describe('BranchPath component', () => {
  let wrapper;
  const sourceBranch = 'feature-branch';
  const sourceBranchUri = '/project/feature-branch';
  const targetBranch = 'main';
  const targetBranchUri = '/project/main';

  const findSectionHeader = () => wrapper.findComponent(DrawerSectionHeader);
  const findBranchDetails = () => wrapper.findComponent(BranchDetails);

  const createComponent = () => {
    return shallowMount(BranchPath, {
      propsData: { sourceBranch, sourceBranchUri, targetBranch, targetBranchUri },
    });
  };

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('rendering', () => {
    it('renders the header', () => {
      expect(findSectionHeader().text()).toBe('Path');
    });

    it('renders the branch details', () => {
      expect(findBranchDetails().props()).toStrictEqual({
        sourceBranch: { name: sourceBranch, uri: sourceBranchUri },
        targetBranch: { name: targetBranch, uri: targetBranchUri },
      });
    });
  });
});
