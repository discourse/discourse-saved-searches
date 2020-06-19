import { withPluginApi } from "discourse/lib/plugin-api";
import discourseComputed from "discourse-common/utils/decorators";

function initializeSavedSearches(api) {
  api.modifyClass("model:user", {
    @discourseComputed("trust_level", "staff")
    savedSearchesAllowed(trust_level, staff) {
      return (
        Discourse.SiteSettings.saved_searches_enabled &&
        (trust_level >= Discourse.SiteSettings.saved_searches_min_trust_level ||
          staff)
      );
    }
  });
}

export default {
  name: "apply-saved-searches",

  initialize() {
    withPluginApi("0.8.9", initializeSavedSearches);
  }
};
