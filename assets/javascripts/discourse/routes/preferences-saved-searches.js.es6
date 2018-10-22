import RestrictedUserRoute from "discourse/routes/restricted-user";

export default RestrictedUserRoute.extend({
  setupController(controller, user) {
    if (!user.get("savedSearchesAllowed")) {
      return this.transitionTo("preferences.account");
    }

    controller.setProperties({ model: user });
  }
});
