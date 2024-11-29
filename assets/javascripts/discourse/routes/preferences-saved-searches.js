import { service } from "@ember/service";
import RestrictedUserRoute from "discourse/routes/restricted-user";

export default class PreferencesSavedSearches extends RestrictedUserRoute {
  @service router;

  setupController(controller, model) {
    if (!model.can_use_saved_searches) {
      return this.router.transitionTo("preferences.account");
    }

    controller.setProperties({
      model,
      savedSearches: model.saved_searches || [],
    });
  }
}
