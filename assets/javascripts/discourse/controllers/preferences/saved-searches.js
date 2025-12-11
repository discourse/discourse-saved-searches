import Controller from "@ember/controller";
import { action } from "@ember/object";
import { dependentKeyCompat } from "@ember/object/compat";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { removeValueFromArray } from "discourse/lib/array-tools";
import discourseComputed from "discourse/lib/decorators";
import { trackedArray } from "discourse/lib/tracked-tools";
import { i18n } from "discourse-i18n";

export default class PreferencesSavedSearchesController extends Controller {
  @service siteSettings;

  @trackedArray savedSearches;

  isSaving = false;
  saved = false;

  @dependentKeyCompat
  get canAddSavedSearch() {
    return this.savedSearches.length < this.siteSettings.max_saved_searches;
  }

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
    this.savedSearches.push({ query: "", frequency: "daily" });
  }

  @action
  removeSavedSearch(savedSearch) {
    removeValueFromArray(this.savedSearches, savedSearch);
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
