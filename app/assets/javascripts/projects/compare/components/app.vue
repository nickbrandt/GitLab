<script>
import BranchDropdown from './branch_dropdown.vue';

export default {
  components: {
    BranchDropdown,
  },
  props: {
    refsProjectPath: {
      type: String,
      required: true,
    },
    paramsFrom: {
      type: String,
      required: true,
    },
    paramsTo: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="row">
    <div class="col-lg-6">
      <div class="card">
        <div class="card-header gl-font-weight-bold gl-py-3 gl-line-height-normal">
          {{ s__('CompareBranches|Source') }}
        </div>
        <div class="card-body clearfix">
          <branch-dropdown
            :refs-project-path="refsProjectPath"
            params="from"
            :params-branch="paramsFrom"
          />
        </div>
      </div>
    </div>
    <div class="col-lg-6">
      <div class="card">
        <div class="card-header gl-font-weight-bold gl-py-3 gl-line-height-normal">
          {{ s__('CompareBranches|Target') }}
        </div>
        <div class="card-body clearfix">
          <branch-dropdown
            :refs-project-path="refsProjectPath"
            params="to"
            :params-branch="paramsTo"
          />
        </div>
      </div>
    </div>
  </div>
</template>
