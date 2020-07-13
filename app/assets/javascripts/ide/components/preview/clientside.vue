<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { isEmpty, isString } from 'lodash';
import { Manager } from 'smooshpack';
import { listen } from 'codesandbox-api';
import { GlLoadingIcon } from '@gitlab/ui';
import Navigator from './navigator.vue';
import { packageJsonPath } from '../../constants';
import { createPathWithExt } from '../../utils';

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
    ...mapState(['entries', 'promotionSvgPath', 'links', 'codesandboxBundlerUrl', 'stagedFiles']),
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
        entry: `/${this.mainEntry}`,
        showOpenInCodeSandbox: this.showOpenInCodeSandbox,
      };
    },
  },
  watch: {
    stagedFiles: {
      deep: true,
      handler: 'update',
    },
  },
  mounted() {
    this.loading = true;

    return this.loadFileContent(packageJsonPath)
      .then(() => {
        this.loading = false;
      })
      .then(() => this.$nextTick())
      .then(() => this.initPreview());
  },
  beforeDestroy() {
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
    handleWindowMessage(e) {
      if (e.data.codesandbox) {
        return;
      }
      console.log('[clientside.vue] Got a message!', e);
    },
    loadFileContent(path) {
      return this.getFileData({ path, makeFileActive: false }).then(() =>
        this.getRawFileData({ path }),
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
    update(...args) {
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
          isFile: p => Promise.resolve(Boolean(this.entries[createPathWithExt(p)])),
          readFile: p => this.loadFileContent(createPathWithExt(p)).then(content => content),
        },
        ...(bundlerURL ? { bundlerURL } : {}),
      };

      this.manager = new Manager('#ide-preview', this.sandboxOpts, settings);

      window.addEventListener('message', ({ data: { type, payload } }) => {
        if (type !== 'gitlab-ide') {
          return;
        }

        const { path, requestId } = payload;

        console.log('[clientside.vue] handling', path, requestId);

        this.loadFileContent(path)
          .then(contentParam => {
            const isBase64 = isString(contentParam);
            const content = isBase64
              ? Uint8Array.from(atob(contentParam), c => c.charCodeAt(0))
              : contentParam;

            return this.getIframeContentWindow().then(contentWindow => {
              contentWindow.postMessage(
                {
                  type: 'gitlab-ide-response',
                  payload: {
                    path,
                    content,
                    contentType: 'image/png',
                    requestId,
                  },
                },
                '*',
              );
            });
          })
          .catch(e => {
            console.error('[clientside.vue] something bad happened fetching content for', path, e);
          });
      });
    },
    getIframeContentWindow() {
      const iframe = this.$el.querySelector('iframe');

      if (iframe?.contentWindow) {
        return Promise.resolve(iframe.contentWindow);
      }

      return new Promise(resolve => setTimeout(resolve, 500)).then(() =>
        this.getIframeContentWindow(),
      );
    },
  },
};
</script>

<template>
  <div class="preview h-100 w-100 d-flex flex-column">
    <template v-if="showPreview">
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
