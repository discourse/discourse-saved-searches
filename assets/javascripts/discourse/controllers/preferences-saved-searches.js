import Controller from "@ember/controller";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { propertyLessThan } from "discourse/lib/computed";

export default Controller.extend({
  savedSearches: null,

  isSaving: false,
  saved: false,

  canAddSavedSearch: propertyLessThan(
    "savedSearches.length",
    "siteSettings.max_saved_searches"
  ),

  @action
  addSavedSearch() {
    this.savedSearches.pushObject({ query: "" });
  },

  @action
  removeSavedSearch(savedSearch) {
    this.savedSearches.removeObject(savedSearch);
  },

  @action
  save() {
    this.setProperties({ isSaving: true, saved: false });

    const savedSearches = this.savedSearches
      .map((savedSearch) => {
        const query = savedSearch.query.trim();
        return query ? query : null;
      })
      .compact();

    return ajax(`/u/${this.model.username}/preferences/saved-searches`, {
      type: "PUT",
      dataType: "json",
      data: { searches: savedSearches },
    })
      .then(() =>
        this.setProperties({
          saved: true,
          "model.saved_searches": savedSearches,
        })
      )
      .catch(popupAjaxError)
      .finally(() => this.set("isSaving", false));
  },
});
