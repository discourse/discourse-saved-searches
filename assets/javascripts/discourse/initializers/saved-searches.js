import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "saved-searches",

  initialize() {
    withPluginApi((api) => {
      api.replaceIcon(
        "notification.saved_searches.notification",
        "magnifying-glass"
      );
    });
  },
};
