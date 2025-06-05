import Component from "@ember/component";
import { LinkTo } from "@ember/routing";
import { classNames, tagName } from "@ember-decorators/component";
import { i18n } from "discourse-i18n";

@tagName("li")
@classNames("user-preferences-nav-outlet", "saved-searches")
export default class SavedSearches extends Component {
  <template>
    {{#if this.model.can_use_saved_searches}}
      <LinkTo @route="preferences.savedSearches">
        {{i18n "saved_searches.title"}}
      </LinkTo>
    {{/if}}
  </template>
}
