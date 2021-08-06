import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "saved-searches",

  initialize() {
    withPluginApi("0.12.0", (api) => {
      api.replaceIcon("notification.saved_searches.notification", "search");
    });
  },
};
