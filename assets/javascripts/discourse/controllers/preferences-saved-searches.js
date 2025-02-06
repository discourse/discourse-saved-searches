import Controller from "@ember/controller";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { propertyLessThan } from "discourse/lib/computed";
import discourseComputed from "discourse/lib/decorators";
import { i18n } from "discourse-i18n";

export default class PreferencesSavedSearchesController extends Controller {
  savedSearches = null;
  isSaving = false;
  saved = false;

  @propertyLessThan("savedSearches.length", "siteSettings.max_saved_searches")
  canAddSavedSearch;

  @discourseComputed
  savedSearchFrequencyOptions() {
    return [
      {
        name: i18n("saved_searches.frequency_options.immediately"),
        value: "immediately",
      },
      {
        name: i18n("saved_searches.frequency_options.hourly"),
        value: "hourly",
      },
      {
        name: i18n("saved_searches.frequency_options.daily"),
        value: "daily",
      },
      {
        name: i18n("saved_searches.frequency_options.weekly"),
        value: "weekly",
      },
    ];
  }

  @action
  addSavedSearch() {
    this.savedSearches.pushObject({ query: "", frequency: "daily" });
  }

  @action
  removeSavedSearch(savedSearch) {
    this.savedSearches.removeObject(savedSearch);
  }

  @action
  save() {
    this.setProperties({ isSaving: true, saved: false });

    const savedSearches = this.savedSearches.filter(
      (savedSearch) => !!savedSearch.query.trim()
    );

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
  }
}
