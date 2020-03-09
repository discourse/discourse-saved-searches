import computed from "ember-addons/ember-computed-decorators";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default Ember.Controller.extend({
  saving: false,
  maxSavedSearches: 5,

  @computed("model.saved_searches")
  searchStrings() {
    let records = [];
    (this.get("model.saved_searches") || []).forEach(s => {
      records.push({ query: s });
    });
    while (records.length < this.get("maxSavedSearches")) {
      records.push({ query: "" });
    }
    return records;
  },

  actions: {
    save() {
      this.setProperties({ saved: false, isSaving: true });

      const searches = this.get("searchStrings")
        .map(s => {
          return s.query ? s.query : null;
        })
        .compact();

      this.set("model.saved_searches", searches);

      return ajax("/saved_searches", {
        type: "PUT",
        dataType: "json",
        data: {
          searches: searches
        }
      }).then((result, error) => {
        this.setProperties({ saved: true, isSaving: false });
        if (error) {
          popupAjaxError(error);
        }
      });
    }
  }
});
