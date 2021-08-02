import RestrictedUserRoute from "discourse/routes/restricted-user";

export default RestrictedUserRoute.extend({
  setupController(controller, model) {
    if (!model.can_use_saved_searches) {
      return this.transitionTo("preferences.account");
    }

    const savedSearches = [];
    if (model.saved_searches) {
      model.saved_searches.forEach((query) => {
        savedSearches.push({ query });
      });
    }

    controller.setProperties({ model, savedSearches });
  },
});
