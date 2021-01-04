import { acceptance, exists } from "discourse/tests/helpers/qunit-helpers";

acceptance("Saved Searches", function (needs) {
  needs.user();
  needs.settings({
    saved_searches_enabled: true,
    saved_searches_min_trust_level: 0,
  });
  needs.pretender((server) => {
    server.put("/saved_searches", () => {
      // eslint-disable-line no-undef
      return [200, { "Content-Type": "application/json" }, { success: "OK" }];
    });
  });

  test("Saved Search preferences", (assert) => {
    visit("/u/eviltrout/preferences");

    andThen(() => {
      assert.ok(
        exists(".preferences-nav .saved-searches"),
        "saved search section exists"
      );
    });

    click(".preferences-nav .saved-searches a");

    andThen(() => {
      assert.ok(
        exists(".saved-searches-controls input"),
        "saved search inputs exist"
      );
    });

    fillIn(".saved-searches-controls:first input", "ballista");
    click(".save-changes");
    assert.ok(!exists(".saved"), "it hasn't been saved yet");
    andThen(() => {
      assert.ok(exists(".saved"), "it displays the saved message");
    });
  });
});
