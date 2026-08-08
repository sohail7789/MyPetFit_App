# Backlog

Product and engineering work that is understood but deliberately not being
done yet. Each item states what the problem is, why it is being deferred, and
what "done" would look like — so a future sprint can pick it up without
re-deriving the reasoning.

---

## Progressive disclosure for analytics surfaces

**Raised:** Sprint 3, after Feature 5 (health milestones).
**Status:** ✅ Completed in Sprint 3, Feature 7.

### The problem

Report History now stacks five analytics sections on one scroll — the trend
graph, what changed, category evolution, health milestones, and the report
timeline itself — above the grouped list of past reports. Each section is
individually justified and none is noise, but together they ask a reader to
scan a lot of screen before reaching the record they opened the tab to find.

The density is a consequence of the module working, not of it being built
wrongly. Every section answers a different question about the same history.

### Why it is deferred

Solving it mid-sprint would mean redesigning surfaces while features are
still landing on them, and any collapse behaviour built now would have to be
reworked once the analytics summary exists as a framing element. Deferring
costs nothing today: the sections are correct, ordered, and readable — there
are simply many of them.

### What done looks like

* Analytics sections on Report History become collapsible, with the collapsed
  state showing enough to decide whether to open — a heading and a one-line
  answer, not a bare title.
* Default expansion is a product decision per section, not a uniform "all
  collapsed": the most recent change probably opens, a ten-entry milestone
  history probably does not.
* Expansion is **local UI state for the current visit, never persisted** —
  not to SharedPreferences, not to Firestore, not to a provider. It survives
  ordinary rebuilds, resets when the pet changes, and starts from the
  defaults each time the screen is built. *(Corrected during Feature 7: an
  earlier draft of this item proposed persisting it. A reading posture is not
  a preference worth storing, and a remembered expansion would eventually
  show one pet's section state over another's record.)*
* The mechanism is a reusable widget in `lib/analytics/widgets`, not bespoke
  per section, so the veterinarian portal and web dashboard inherit the same
  behaviour.
* Collapsed sections stay reachable to screen readers and to text scaling —
  a disclosure control that hides content from assistive technology is worse
  than the density it fixes.

### Notes

* The analytics summary dashboard (Feature 6) is the natural anchor for this:
  once an executive summary sits at the top, the detailed sections below it
  are what progressive disclosure collapses *around*.
* Retention is capped per pet today (see `AssessmentSeriesAdapter.fromQuiz`),
  so section lengths are currently bounded. When the cap is raised, density
  stops being a layout preference and becomes a usability requirement.

### How it shipped

Feature 7 delivered it as `AnalyticsSection` — a provider-free disclosure
primitive that builds its detail only while open — with the health overview
and the trend graph left always visible, and insights, category progress,
milestone history and the assessment timeline behind headings. The closed
state of each carries what must not wait for a tap: an unled caution, the
coverage counts, and the newest assessment row in full.

One thing found on the way: Report History branched on `history.isEmpty`
without consulting `QuizProvider.isLoaded`, so a cold start could show "No
reports yet" over history that was still being restored. Fixed with the
existing `AnalyticsLoadingState`, and covered by a regression test.
