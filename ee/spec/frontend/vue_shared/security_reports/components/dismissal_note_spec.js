import { shallowMount } from '@vue/test-utils';
import component from 'ee/vue_shared/security_reports/components/dismissal_note.vue';
import EventItem from 'ee/vue_shared/security_reports/components/event_item.vue';

describe('dismissal note', () => {
  const now = new Date();
  const feedback = {
    author: {
      name: 'Tanuki',
      username: 'gitlab',
    },
    created_at: now.toString(),
  };
  const pipeline = {
    path: '/path-to-the-pipeline',
    id: 2,
  };
  const project = {
    value: 'Project one',
    url: '/path-to-the-project',
  };

  describe('with no attached project or pipeline', () => {
    let wrapper;

    beforeEach(() => {
      wrapper = shallowMount(component, {
        propsData: { feedback },
      });
    });

    it('should pass the author to the event item', () => {
      expect(wrapper.find(EventItem).props('author')).toBe(feedback.author);
    });

    it('should pass the created date to the event item', () => {
      expect(wrapper.find(EventItem).props('createdAt')).toBe(feedback.created_at);
    });

    it('should return the event text with no project data', () => {
      expect(wrapper.text()).toBe('Dismissed');
    });
  });

  describe('with an attached project', () => {
    let wrapper;

    beforeEach(() => {
      wrapper = shallowMount(component, {
        propsData: { feedback, project },
      });
    });

    it('should return the event text with project data', () => {
      expect(wrapper.text()).toBe(`Dismissed at ${project.value}`);
    });
  });

  describe('with an attached pipeline', () => {
    let wrapper;

    beforeEach(() => {
      wrapper = shallowMount(component, {
        propsData: { feedback: { ...feedback, pipeline } },
      });
    });

    it('should return the event text with project data', () => {
      expect(wrapper.text()).toBe(`Dismissed on pipeline #${pipeline.id}`);
    });
  });

  describe('with an attached pipeline and project', () => {
    let wrapper;

    beforeEach(() => {
      wrapper = shallowMount(component, {
        propsData: { feedback: { ...feedback, pipeline }, project },
      });
    });

    it('should return the event text with project data', () => {
      expect(wrapper.text()).toBe(`Dismissed on pipeline #${pipeline.id} at ${project.value}`);
    });
  });

  describe('with unsafe data', () => {
    let wrapper;
    const unsafeProject = {
      ...project,
      value: 'Foo <script>alert("XSS")</script>',
    };

    beforeEach(() => {
      wrapper = shallowMount(component, {
        propsData: {
          feedback,
          project: unsafeProject,
        },
      });
    });

    it('should escape the project name', () => {
      // Note: We have to check the computed prop here because
      // vue test utils unescapes the result of wrapper.text()

      expect(wrapper.vm.eventText).not.toContain(project.value);
      expect(wrapper.vm.eventText).toContain(
        'Foo &lt;script&gt;alert(&quot;XSS&quot;)&lt;/script&gt;',
      );
    });
  });
});
