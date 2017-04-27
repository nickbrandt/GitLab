import Vue from 'vue';
import eventHub from './event_hub';
import RelatedIssuesBlock from './components/related_issues_block.vue';
import RelatedIssuesStore from './stores/related_issues_store';
import RelatedIssuesService from './services/related_issues_service';

class RelatedIssuesRoot {
  constructor(wrapperElement) {
    this.wrapperElement = wrapperElement;
    const endpoint = this.wrapperElement.dataset.endpoint;

    this.store = new RelatedIssuesStore({

    });
    this.service = new RelatedIssuesService(endpoint);
  }

  init() {
    this.bindEvents();

    this.fetchRelatedIssues();

    this.render();

    window.todoTestingUpdateRelatedIssues = () => {
      this.store.setRelatedIssues([{
        title: 'This is the title of my issue',
        state: 'opened',
        reference: '#1222',
        path: '/gitlab-org/gitlab-ce/issues/0-fake-issue-id',
      }, {
        title: 'Another title to my other issue',
        state: 'closed',
        reference: '#43',
        path: '/gitlab-org/gitlab-ce/issues/0-fake-issue-id',
      }, {
        title: 'One last title to my other issue',
        state: 'closed',
        reference: '#432',
        path: '/gitlab-org/gitlab-ce/issues/0-fake-issue-id',
      }, {
        title: 'An issue from another project',
        state: 'closed',
        reference: 'design/#1222',
        path: '/gitlab-org/gitlab-ce/issues/0-fake-issue-id',
      }]);
    };
  }

  bindEvents() {
    this.onShowAddRelatedIssuesFormWrapper = this.onShowAddRelatedIssuesForm.bind(this);

    eventHub.$on('showAddRelatedIssuesForm', this.onShowAddRelatedIssuesFormWrapper);
  }

  unbindEvents() {
    eventHub.$off('showAddRelatedIssuesForm', this.onShowAddRelatedIssuesFormWrapper);
  }

  render() {
    this.vm = new Vue({
      el: this.wrapperElement,
      data: this.store.state,
      components: {
        relatedIssuesBlock: RelatedIssuesBlock,
      },
      /* * /
      template: `
        <relatedIssuesBlock
          :related-issues="relatedIssues"
          :fetch-error="fetchError"
          :is-add-related-issues-form-visible="isAddRelatedIssuesFormVisible" />
      `,
      /* */
      render: createElement => createElement('related-issues-block', {
        props: {
          relatedIssues: this.store.state.relatedIssues,
          fetchError: this.store.state.fetchError,
          isAddRelatedIssuesFormVisible: this.store.state.isAddRelatedIssuesFormVisible,
        },
      }),
    });
  }

  onShowAddRelatedIssuesForm() {
    this.store.setIsAddRelatedIssuesFormVisible(true);
  }

  fetchRelatedIssues() {
    this.service.fetchRelatedIssues()
      .then((issues) => {
        this.store.setRelatedIssues(issues);
      })
      .catch((err) => {
        this.store.setFetchError(err);
      });
  }

  destroy() {
    this.unbindEvents();
    if (this.vm) {
      this.vm.$destroy();
    }
  }
}

export default RelatedIssuesRoot;
