<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { isEmpty, isString, debounce } from 'lodash';
import { Manager } from 'smooshpack';
import { listen } from 'codesandbox-api';
import { GlLoadingIcon } from '@gitlab/ui';
import Navigator from './navigator.vue';
import { packageJsonPath } from '../../constants';
import { createPathWithExt } from '../../utils';
import eventHub from '../../eventhub';

export default {
  components: {
    Navigator,
    GlLoadingIcon,
  },
  data() {
    return {
      manager: {},
      loading: false,
      sandpackReady: false,
    };
  },
  computed: {
    ...mapState(['entries', 'promotionSvgPath', 'links', 'codesandboxBundlerUrl']),
    ...mapGetters(['packageJson', 'currentProject']),
    normalizedEntries() {
      return Object.keys(this.entries).reduce((acc, path) => {
        const file = this.entries[path];

        if (file.type === 'tree' || !(file.raw || file.content)) return acc;

        return {
          ...acc,
          [`/${path}`]: {
            code: file.content || file.raw,
          },
        };
      }, {});
    },
    mainEntry() {
      if (!this.packageJson.raw) return false;

      const parsedPackage = JSON.parse(this.packageJson.raw);

      return parsedPackage.main;
    },
    showPreview() {
      return this.mainEntry && !this.loading;
    },
    showEmptyState() {
      return !this.mainEntry && !this.loading;
    },
    showOpenInCodeSandbox() {
      return this.currentProject && this.currentProject.visibility === 'public';
    },
    sandboxOpts() {
      return {
        files: { ...this.normalizedEntries },
        showOpenInCodeSandbox: this.showOpenInCodeSandbox,
      };
    },
  },
  mounted() {
    this.onFilesChangeCallback = debounce(() => this.update(), 2000);
    eventHub.$on('ide.files.change', this.onFilesChangeCallback);

    this.loading = true;

    return this.loadFileContent(packageJsonPath)
      .then(() => {
        if (this.entries['sandbox.config.json']) {
          return this.loadFileContent('sandbox.config.json');
        }

        return null;
      })
      .then(() => {
        this.loading = false;
      })
      .then(() => this.$nextTick())
      .then(() => this.initPreview());
  },
  beforeDestroy() {
    eventHub.$off('ide.files.change', this.onFilesChangeCallback);

    if (!isEmpty(this.manager)) {
      this.manager.listener();
    }
    this.manager = {};

    if (this.listener) {
      this.listener();
    }

    clearTimeout(this.timeout);
    this.timeout = null;
  },
  methods: {
    ...mapActions(['getFileData', 'getRawFileData']),
    ...mapActions('clientside', ['pingUsage']),
    loadFileContent(path) {
      return this.getFileData({ path, makeFileActive: false }).then(() =>
        this.getRawFileData({ path, onlyCacheOnce: true }),
      );
    },
    initPreview() {
      if (!this.mainEntry) return null;

      this.pingUsage();

      return this.loadFileContent(this.mainEntry)
        .then(() => this.$nextTick())
        .then(() => {
          this.initManager();

          this.listener = listen(e => {
            switch (e.type) {
              case 'done':
                this.sandpackReady = true;
                break;
              default:
                break;
            }
          });
        });
    },
    update() {
      if (!this.sandpackReady) return;

      clearTimeout(this.timeout);

      this.timeout = setTimeout(() => {
        if (isEmpty(this.manager)) {
          this.initPreview();

          return;
        }

        this.manager.updatePreview(this.sandboxOpts);
      }, 250);
    },
    initManager() {
      const { codesandboxBundlerUrl: bundlerURL } = this;

      const settings = {
        fileResolver: {
          isFile: p => {
            return Promise.resolve(Boolean(this.entries[createPathWithExt(p)]));
          },
          readFile: p => {
            console.log('[clientside] readFile', p);

            return this.resolveFileContent(createPathWithExt(p));
          },
          readFileInfo: p => {
            console.log('[clientside] readFileInfo', p);
            return this.resolveFileContentInfo(createPathWithExt(p));
          },
        },
        ...(bundlerURL ? { bundlerURL } : {}),
      };

      this.manager = new Manager('#ide-preview', this.sandboxOpts, settings);
    },
    resolveFileContent(path) {
      return this.loadFileContent(path).then(contentParam => {
        const isBase64 = isString(contentParam);
        const content = isBase64
          ? Uint8Array.from(atob(contentParam), c => c.charCodeAt(0))
          : contentParam;

        return content;
      });
    },
    resolveFileContentInfo(path) {
      return this.resolveFileContent(path).then(content => {
        const contentType = this.entries[path].mime_type;

        return {
          content,
          contentType,
        };
      });
    },
  },
};
</script>

<template>
  <div class="preview h-100 w-100 d-flex flex-column">
    <template v-if="showPreview">
      <navigator :manager="manager" />
      <div id="ide-preview"></div>
    </template>
    <div
      v-else-if="showEmptyState"
      v-once
      class="d-flex h-100 flex-column align-items-center justify-content-center svg-content"
    >
      <img :src="promotionSvgPath" :alt="s__('IDE|Live Preview')" width="130" height="100" />
      <h3>{{ s__('IDE|Live Preview') }}</h3>
      <p class="text-center">
        {{ s__('IDE|Preview your web application using Web IDE client-side evaluation.') }}
      </p>
      <a
        :href="links.webIDEHelpPagePath"
        class="btn btn-primary"
        target="_blank"
        rel="noopener noreferrer"
      >
        {{ s__('IDE|Get started with Live Preview') }}
      </a>
    </div>
    <gl-loading-icon v-else size="lg" class="align-self-center mt-auto mb-auto" />
  </div>
</template>
