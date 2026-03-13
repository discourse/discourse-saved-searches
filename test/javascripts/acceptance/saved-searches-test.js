import { click, fillIn, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance("Saved Searches", function (needs) {
  needs.user({ can_use_saved_searches: true });

  needs.settings({ max_saved_searches: 5 });

  needs.pretender((server) => {
    server.put("/u/eviltrout/preferences/saved-searches", () => {
      return [200, { "Content-Type": "application/json" }, { success: "OK" }];
    });
  });

  test("Saved Search preferences", async (assert) => {
    await visit("/u/eviltrout/preferences");

    assert.dom(".saved-searches").exists("saved search section exists");

    await click(".saved-searches a");

    assert
      .dom(".saved-searches-controls .add-saved-search")
      .exists("can add saved search");

    await click(".saved-searches-controls .add-saved-search");

    assert
      .dom(".saved-searches-controls input")
      .exists("saved search inputs exist");

    await click(".saved-searches-controls .add-saved-search");
    assert
      .dom(".saved-searches-controls input")
      .exists({ count: 2 }, "can add more than one saved search");

    await click(".saved-searches-controls .remove-saved-search");
    assert
      .dom(".saved-searches-controls input")
      .exists({ count: 1 }, "can remove saved searches");

    await fillIn(".saved-searches-controls input", "ballista");
    assert.dom(".saved").doesNotExist("hasn't been saved yet");

    await click(".save-changes");
    assert.dom(".saved").exists("displays the saved message");
  });
});
