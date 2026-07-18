# Chapter 6 — The White Teeth of the Sky (design)

The finale. Both Chapter 5 roads — the boxcar jump with Pat, the barge
landfall alone — converge below the Pyrenees and climb out of the war.
The chapter is two scenes long on purpose: one last warm room, then the
cold. Everything the campaign has tracked comes due here, and nothing
new is introduced except altitude.

## Structure

**ch6_foothills — the shepherd's hut.** The last roof in France: stone,
smoke, hanging cheeses, a dog with judicial authority, and a Basque
shepherd who has taken ninety-one parcels over the col ("the col does
not count. The col only weighs"). `with_pat` seats Pat at the fire and
gives the shepherd a second parcel to argue with God about. The scene's
one hard beat is the warning, delivered plainly: a man in a city coat
went up the valley yesterday, asking for a parcel by name. **He is ahead
of you, not behind** — the chapter's whole dread in one preposition.
Choice: "we go through" or "his war must be very small" (the shepherd's
answer to the second is the chapter thesis: *he carried it up here
himself. That is not duty. That is a debt he thinks you owe him*).

**ch6_crossing — the shoulder, the cairn, Spain.** A snow shoulder
between crags, wind bands that stream harder as you climb, the far range
pale against the sky. The shepherd's farewell at the grass line ("here my
sheep turn back — and my authority with them"). Halfway up, the figure by
the cairn resolves: small, dark, patient. The confrontation. Then thirty
steps, counted without meaning to, and the thirty-first is Spanish —
"it feels exactly like the others, which is the entire point of borders."

## The confrontation (`voss_cairn.json`)

Voss has out-climbed the player in police shoes to close the file that
is his whole war. The dialogue reads three ledgers:

- **met_voss** — a second meeting gets the margins re-read on the train
  ("'the summer soldier', underlined twice, and beside it, in your hand:
  'which am I?'"); a first meeting gets the old correspondents
  introduction.
- **with_pat** — Pat gets his own node (the police shoes); alone gets
  the coldest line in the game: "the careful ones always arrive alone,
  Sergeant. It is the fee."
- **told_truth_document** — whether the player *knows* where the paper
  went decides which weapon the final choice offers.

Three resolutions, all canon, none a fail state:

| choice | flags | staging |
|---|---|---|
| Tell him the truth (only if known) | `told_voss_truth`, `spared_voss` | He sits down on the cairn among every stone left by every leaving hand. "Some men are killed. His kind are concluded." |
| Walk past | `spared_voss`, `voss_fired` | One shot behind you, into the snow, wide and flat and final. You do not turn around. |
| The stones | `killed_voss` | Whiteout. Eleven seconds — one per statement in his folder. The mountain does not testify. |

("Beaten by everyone", the alone/no-truth spoken option, spares him with
no shot: he steps back from the path — procedure, concluding.)

## The ending cards

Over the fade, the ledger is read back, each card chosen by flags:
companion (`with_pat`), Voss (`killed_voss` / `told_voss_truth` /
spared), the paper (`told_truth_document` → eleven days; otherwise he
reads about it in a newspaper like everyone else), the sixth of June,
the fallen (`beranger_taken` / `lucien_marked` / `freeman_lost`, with a
no-flags fallback about the line that was never written down), and the
Paine book (`paine_kept` or the flour tin). Close: "The ledger never
balances. It was never supposed to. It was only supposed to be carried."
THE END → title, `chapter = 7`, beat cleared.

## Headless drives

`--autoplay` walks farewell → climb → dialogue (walk-past) → Spain →
cards → title. `--autoplay-fail` picks the kill. `--ch6-pat` (direct
scene loads) sets with_pat/met_voss/told_truth_document for the
together/truth variant. Snaps: `ch6_hut`, `ch6_talk`, `ch6_ridge`,
`ch6_cairn`, `ch6_concluded`/`ch6_whiteout`, `ch6_spain`.
