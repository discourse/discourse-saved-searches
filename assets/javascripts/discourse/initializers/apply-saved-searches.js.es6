import { withPluginApi } from 'discourse/lib/plugin-api';

function initializeSavedSearches(api) {
  api.modifyClass('model:user', {
    savedSearchesAllowed: function() {
      if (!Discourse.SiteSettings.saved_searches_enabled) { return false; }
      if (this.get('staff')) { return true; }

      // Author Level 3 and higher get access to this plugin
      return (
        this.get('trust_level') >= Discourse.SiteSettings.saved_searches_min_trust_level &&
        (this.get('author_level') || 0) > 2
      );
    }.property('trust_level')
  });
}

export default {
  name: "apply-saved-searches",

  initialize() {
    withPluginApi('0.8.9', initializeSavedSearches);
  }
};
