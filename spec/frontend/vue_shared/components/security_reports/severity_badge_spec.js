import { shallowMount } from '@vue/test-utils';
import SeverityBadge from 'ee/vue_shared/security_reports/components/severity_badge.vue';
let wrapper;

describe('Severity Badge', () => {

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when it renders', ()=>{
    it('renders the component with critical badge', () => {
      wrapper = shallowMount(SeverityBadge, {
        propsData: {
          severity: 'critical'
        }
      });
  
      expect(wrapper.findAll('span.text-danger-800').exists()).toBe(true);
    });
  
    it('renders the component with high badge', () => {
      wrapper = shallowMount(SeverityBadge, {
        propsData: {
          severity: 'high'
        }
      });
  
      expect(wrapper.findAll('span.text-danger-600').exists()).toBe(true);
    }); 
  });

  describe('computed props', ()=>{
    describe('hasSeverityBadge', () =>{
      describe('when severity is defined', ()=>{
        it('returns true', ()=>{
          wrapper = shallowMount(SeverityBadge, {
            propsData: {
              severity: 'critical'
            }
          });

          expect(wrapper.vm.hasSeverityBadge).toBe(true);
        })
      });

      describe('when severity is a space string', ()=>{
        it('returns false', ()=>{
          wrapper = shallowMount(SeverityBadge, {
            propsData: {
              severity: ' '
            }
          });

          expect(wrapper.vm.hasSeverityBadge).toBe(false);
        })
      });    
      
      describe('when severity empty string', ()=>{
        it('returns false', ()=>{
          wrapper = shallowMount(SeverityBadge, {
            propsData: {
              severity: ''
            }
          });

          expect(wrapper.vm.hasSeverityBadge).toBe(false);
        })
      });      
      
    });

  });

});
