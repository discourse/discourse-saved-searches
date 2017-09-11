import computed from 'ember-addons/ember-computed-decorators';
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';

export default Ember.Controller.extend({
  saving: false,

  @computed('model.author_level')
  maxSavedSearches(authorLevel) {
    if (authorLevel && authorLevel > 2) {
      if (authorLevel >= 7) { return 15; }
      if (authorLevel >= 5) { return 10; }
      return 5;
    } else {
      if (this.get('model.staff')) {
        return 15;
      } else {
        return 0;
      }
    }
  },

  @computed('model.saved_searches')
  searchStrings() {
    let records = [];
    (this.get('model.saved_searches')||[]).forEach(s => {
      records.push({query: s});
    });
    while (records.length < this.get('maxSavedSearches')) {
      records.push({query: ''});
    }
    return records;
  },

  saveButtonText: function() {
    return this.get('saving') ? I18n.t('saving') : I18n.t('save');
  }.property('saving'),

  actions: {
    save() {
      this.set('saved', false);

      const searches = this.get('searchStrings').map(s => { return s.query ? s.query : null; }).compact();

      this.set('model.saved_searches', searches);

      return ajax('/saved_searches', {
        type: 'PUT',
        dataType: 'json',
        data: {
          searches: searches
        }
      }).then((result, error) => {
        this.set('saved', true);
        if (error) {
          popupAjaxError(error);
        }
      });
    }
  }

});
