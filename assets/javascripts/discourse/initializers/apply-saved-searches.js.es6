import { withPluginApi } from 'discourse/lib/plugin-api';

function initializeSavedSearches(api) {
  api.modifyClass('model:user', {
    savedSearchesAllowed: function() {
      return (
        Discourse.SiteSettings.saved_searches_enabled &&
          (this.get('trust_level') >= Discourse.SiteSettings.saved_searches_min_trust_level || this.get('staff'))
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
