const removeTitle = el => {
  // Removing titles so its not showing tooltips also

  el.dataset.originalTitle = '';
  el.setAttribute('title', '');
};

const getPreloadedUserInfo = dataset => {
  const userId = dataset.user || dataset.userId;
  const { username, name, avatarUrl } = dataset;

  return {
    userId,
    username,
    name,
    avatarUrl,
  };
};

/**
 * Adds a UserPopover component to the body, hands over as much data as the target element has in data attributes.
 * loads based on data-user-id more data about a user from the API and sets it on the popover
 */
const populateUserInfo = async user => {
  const loadUsersCache = import(
    /* webpackChunkName: 'initUserPopover' */ './lib/utils/users_cache'
  );
  const loadSanitize = import('~/lib/dompurify');

  const [{ default: UsersCache }, { sanitize }] = await Promise.all([loadUsersCache, loadSanitize]);
  const { userId } = user;

  return Promise.all([UsersCache.retrieveById(userId), UsersCache.retrieveStatusById(userId)]).then(
    ([userData, status]) => {
      if (userData) {
        Object.assign(user, {
          avatarUrl: userData.avatar_url,
          username: userData.username,
          name: userData.name,
          location: userData.location,
          bio: userData.bio,
          bioHtml: sanitize(userData.bio_html),
          workInformation: userData.work_information,
          websiteUrl: userData.website_url,
          loaded: true,
        });
      }

      if (status) {
        Object.assign(user, {
          status,
        });
      }

      return user;
    },
  );
};

const initializedPopovers = new Map();

export default async (elements = document.querySelectorAll('.js-user-link')) => {
  const filteredUserLinks = Array.from(elements).filter(
    ({ dataset }) => dataset.user || dataset.userId,
  );

  if (filteredUserLinks.length === 0) {
    return [];
  }

  const loadUserPopover = import(
    /* webpackChunkName: 'initUserPopover' */ './vue_shared/components/user_popover/user_popover.vue'
  );
  const loadVue = import('vue');

  const [{ default: UserPopover }, { default: Vue }] = await Promise.all([
    loadUserPopover,
    loadVue,
  ]);

  const UserPopoverComponent = Vue.extend(UserPopover);

  return filteredUserLinks.map(el => {
    if (initializedPopovers.has(el)) {
      return initializedPopovers.get(el);
    }

    const user = {
      location: null,
      bio: null,
      workInformation: null,
      status: null,
      loaded: false,
    };
    const renderedPopover = new UserPopoverComponent({
      propsData: {
        target: el,
        user,
      },
    });

    initializedPopovers.set(el, renderedPopover);

    renderedPopover.$mount();

    el.addEventListener('mouseenter', ({ target }) => {
      removeTitle(target);
      const preloadedUserInfo = getPreloadedUserInfo(target.dataset);

      Object.assign(user, preloadedUserInfo);

      if (preloadedUserInfo.userId) {
        populateUserInfo(user);
      }
    });
    el.addEventListener('mouseleave', ({ target }) => {
      target.removeAttribute('aria-describedby');
    });

    return renderedPopover;
  });
};
