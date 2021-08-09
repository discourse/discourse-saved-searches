import { withPluginApi } from "discourse/lib/plugin-api";
import discourseComputed from "discourse-common/utils/decorators";

function initializeSavedSearches(api, siteSettings) {
  api.modifyClass("model:user", {
    @discourseComputed("trust_level", "staff")
    savedSearchesAllowed(trust_level, staff) {
      return (
        siteSettings.saved_searches_enabled &&
        (trust_level >= siteSettings.saved_searches_min_trust_level || staff)
      );
    },
  });
}

export default {
  name: "apply-saved-searches",

  initialize(container) {
    let siteSettings = container.lookup("site-settings:main");
    withPluginApi("0.8.9", (api) => initializeSavedSearches(api, siteSettings));
  },
};
