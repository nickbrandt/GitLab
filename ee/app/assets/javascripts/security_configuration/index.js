import Vue from 'vue';
import SecurityConfigurationApp from './components/app.vue';

// @TODO - this is just temp - move this to dataset
const features = [
  {
    name: 'Static Application Security Testing (SAST)',
    description: 'Analyze your source code for known vulnerabilities',
    link: 'http://example.com',
    configured: true,
  },
  {
    name: 'Dynamic Application Security Testing (DAST)',
    description: 'Analyze a review version of your web application',
    link: 'http://example.com',
    configured: false,
  },
  {
    name: 'Container Scanning',
    description: 'Check your Docker images for known vulnerabilities',
    link: 'http://example.com',
    configured: false,
  },
  {
    name: 'Dependency Scanning',
    description: 'Analyze your dependencies for known vulnerabilities',
    link: 'http://example.com',
    configured: true,
  },
  {
    name: 'License Compliance',
    description: 'Search your project dependencies for their licenses and apply policies',
    link: 'http://example.com',
    configured: true,
  },
];

export default function init() {
  const el = document.getElementById('js-security-configuration');
  const { helpPagePath } = el.dataset;

  return new Vue({
    el,
    components: {
      SecurityConfigurationApp,
    },
    render(createElement) {
      return createElement(SecurityConfigurationApp, {
        props: {
          helpPagePath,
          features,
        },
      });
    },
  });
}
