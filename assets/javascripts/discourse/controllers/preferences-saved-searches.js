import Controller from "@ember/controller";
import { action } from "@ember/object";
import discourseComputed from "discourse-common/utils/decorators";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default Controller.extend({
  saving: false,

  @discourseComputed("savedSearches.length", "siteSettings.max_saved_searches")
  canAddSavedSearch(length, max) {
    return length < max;
  },

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
    this.setProperties({ saved: false, isSaving: true });

    const savedSearches = this.savedSearches
      .map((savedSearch) => {
        const query = savedSearch.query.trim();
        return query ? query : null;
      })
      .compact();

    return ajax("/saved_searches", {
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
