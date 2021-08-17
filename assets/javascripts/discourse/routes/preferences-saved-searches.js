import RestrictedUserRoute from "discourse/routes/restricted-user";

export default RestrictedUserRoute.extend({
  setupController(controller, model) {
    if (!model.can_use_saved_searches) {
      return this.transitionTo("preferences.account");
    }

    controller.setProperties({
      model,
      savedSearches: model.saved_searches || [],
    });
  },
});
