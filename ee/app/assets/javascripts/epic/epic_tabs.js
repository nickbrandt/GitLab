import $ from 'jquery';
import initRelatedItemsTree from 'ee/related_items_tree/related_items_tree_bundle';
import initRoadmap from 'ee/roadmap/roadmap_bundle';

export default class EpicTabs {
  constructor() {
    this.wrapper = document.querySelector('.content-wrapper .container-fluid:not(.breadcrumbs)');
    this.epicTabs = this.wrapper.querySelector('.js-epic-tabs-container');
    this.discussionFilterContainer = this.epicTabs.querySelector('.js-discussion-filter-container');

    this.treeTabLoaded = false;
    this.roadmapTabLoaded = false;

    this.bindEvents();
  }

  bindEvents() {
    const $treeTab = $('#tree-tab', this.epicTabs);
    const $roadmapTab = $('#roadmap-tab', this.epicTabs);

    $treeTab.on('show.bs.tab', this.onTreeShow.bind(this));
    $treeTab.on('hide.bs.tab', this.onTreeHide.bind(this));
    $roadmapTab.on('show.bs.tab', this.onRoadmapShow.bind(this));
    $roadmapTab.on('hide.bs.tab', this.onRoadmapHide.bind(this));
  }

  onTreeShow() {
    this.discussionFilterContainer.classList.add('hidden');
    if (!this.treeTabLoaded) {
      initRelatedItemsTree();
      this.treeTabLoaded = true;
    }
  }

  onTreeHide() {
    this.discussionFilterContainer.classList.remove('hidden');
  }

  onRoadmapShow() {
    this.wrapper.classList.remove('container-limited');
    this.discussionFilterContainer.classList.add('hidden');
    if (!this.roadmapTabLoaded) {
      initRoadmap();
      this.roadmapTabLoaded = true;
    }
  }

  onRoadmapHide() {
    this.wrapper.classList.add('container-limited');
    this.discussionFilterContainer.classList.remove('hidden');
  }
}
