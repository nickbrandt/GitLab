import $ from 'jquery';
import initRelatedItemsTree from 'ee/related_items_tree/related_items_tree_bundle';
import initRoadmap from 'ee/roadmap/roadmap_bundle';

export default class EpicTabs {
  constructor() {
    this.epicTreesEnabled = gon.features && gon.features.epicTrees;
    this.wrapper = document.querySelector('.content-wrapper .container-fluid:not(.breadcrumbs)');
    this.epicTabs = this.wrapper.querySelector('.js-epic-tabs-container');
    this.discussionFilterContainer = this.epicTabs.querySelector('.js-discussion-filter-container');

    initRelatedItemsTree();

    this.roadmapTabLoaded = false;

    this.bindEvents();
  }

  bindEvents() {
    const $roadmapTab = $('#roadmap-tab', this.epicTabs);

    $roadmapTab.on('show.bs.tab', this.onRoadmapShow.bind(this));
    $roadmapTab.on('hide.bs.tab', this.onRoadmapHide.bind(this));
  }

  onRoadmapShow() {
    this.wrapper.classList.remove('container-limited');
    if (!this.roadmapTabLoaded) {
      initRoadmap();
      this.roadmapTabLoaded = true;
    }
  }

  onRoadmapHide() {
    this.wrapper.classList.add('container-limited');
  }
}
