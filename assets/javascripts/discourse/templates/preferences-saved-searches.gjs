import { Input } from "@ember/component";
import { fn } from "@ember/helper";
import RouteTemplate from "ember-route-template";
import DButton from "discourse/components/d-button";
import SaveControls from "discourse/components/save-controls";
import { i18n } from "discourse-i18n";
import ComboBox from "select-kit/components/combo-box";

export default RouteTemplate(
  <template>
    <div class="control-group category-saved-searches">
      <label class="control-label">{{i18n "saved_searches.title"}}</label>

      <p>{{i18n
          "saved_searches.description"
          count=@controller.siteSettings.max_saved_searches
        }}</p>

      {{#each @controller.savedSearches as |savedSearch|}}
        <div class="controls saved-searches-controls saved-search">
          <Input @type="text" @value={{savedSearch.query}} />
          <ComboBox
            @content={{@controller.savedSearchFrequencyOptions}}
            @valueProperty="value"
            @value={{savedSearch.frequency}}
            @onChange={{fn (mut savedSearch.frequency)}}
          />
          <DButton
            class="remove-saved-search"
            @icon="trash-can"
            @title="saved_searches.remove"
            @action={{fn @controller.removeSavedSearch savedSearch}}
          />
        </div>
      {{else}}
        <div class="controls saved-searches-controls">
          {{i18n "saved_searches.none"}}
        </div>
      {{/each}}

      {{#if @controller.canAddSavedSearch}}
        <div class="controls saved-searches-controls">
          <DButton
            class="add-saved-search"
            @icon="plus"
            @label="saved_searches.add"
            @action={{@controller.addSavedSearch}}
          />
        </div>
      {{/if}}
    </div>

    <SaveControls
      @model={{@controller}}
      @action={{@controller.save}}
      @saved={{@controller.saved}}
    />
  </template>
);
