import $ from 'jquery';
import initRoadmap from 'ee/roadmap/roadmap_bundle';

export default class EpicTabs {
  constructor() {
    this.wrapper = document.querySelector('.content-wrapper .container-fluid:not(.breadcrumbs)');
    this.epicTabs = this.wrapper.querySelector('.js-epic-tabs-container');
    this.discussionFilterContainer = this.epicTabs.querySelector('.js-discussion-filter-container');

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
