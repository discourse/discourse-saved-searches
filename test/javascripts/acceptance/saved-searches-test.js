import { click, fillIn, visit } from "@ember/test-helpers";
import { test } from "qunit";
import {
  acceptance,
  count,
  exists,
} from "discourse/tests/helpers/qunit-helpers";

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

    assert.ok(exists(".saved-searches"), "saved search section exists");

    await click(".saved-searches a");

    assert.ok(
      exists(".saved-searches-controls .add-saved-search"),
      "can add saved search"
    );

    await click(".saved-searches-controls .add-saved-search");

    assert.ok(
      exists(".saved-searches-controls input"),
      "saved search inputs exist"
    );

    await click(".saved-searches-controls .add-saved-search");
    assert.equal(
      count(".saved-searches-controls input"),
      2,
      "can add more than one saved search"
    );

    await click(".saved-searches-controls .remove-saved-search");
    assert.equal(
      count(".saved-searches-controls input"),
      1,
      "can remove saved searches"
    );

    await fillIn(".saved-searches-controls input", "ballista");
    assert.notOk(exists(".saved"), "it hasn't been saved yet");

    await click(".save-changes");
    assert.ok(exists(".saved"), "it displays the saved message");
  });
});
