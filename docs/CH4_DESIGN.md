# Chapter 4 — The Helpful Ones (design)

Brief §7: *a branch point involving possible betrayal or capture (with a
POW-camp alternate path)... Anton Voss becomes a recurring, escalating
threat.* Chapter 4 is the betrayal chapter: the trust system stops flavouring
lines and starts steering the campaign. Its two endings are both canon —
neither is a fail state — and Chapter 5 opens differently from each.

Historical spine: the Paris evasion networks were broken from inside by
paid infiltrators (Jacques Desoubrie betrayed over a hundred airmen —
young, likeable, endlessly helpful). The chapter's villain is that likeability.

## Cast

- **Madame Béranger** — owns the apartment and, as Sylvie puts it, the air
  you breathe there. Widow, formidable, speaks in flat declaratives. Her
  warnings are oblique because in her city plain speech is suicide:
  *"In this city, the helpful ones bury you."*
- **Lucien** — the line's "helper": brings food, arranges photographs for
  forged papers, knows a *fast route* south. Charming. Asks one question
  too many, always with a reason. **The betrayer.**
- **Lt. Dale Freeman** — a real evader, USAAF, three weeks in the
  apartment with a bad ankle and worse patience. Not a plant — just a man
  whose hurry is as dangerous as treachery. He takes the fast route.
- **Voss** — if Travis is taken: the first direct scene. A policeman, not
  a torturer; the menace is his reasonableness and his file. He has the
  Paine book on the desk.

## Beats

1. **ch4_arrival** — night streets from the station: blackout canyon,
   Sylvie ten steps ahead, one distant patrol beat. She hands you to the
   apartment door and is gone ("The city is not mine."). Upstairs: Mme
   Béranger's rules, Freeman's eagerness, and Lucien — arriving with real
   bread and real charm, delighted an *American* has come.
2. **ch4_apartment** — the confinement day. The heart of the chapter:
   - **Lucien's three probes**, spread across the day, each innocuous:
     your name for the forged papers ("Jean needs a surname history"),
     where you came down ("the line pays the farmers, you see"), and what
     you carry ("they search at the demarcation — better I take anything
     ...sensitive... ahead"). Each: deflect / partial truth / reveal.
     Reveals add **+exposure** (the Ch2 suspicion machinery, repurposed —
     exposure is never fatal here; it prices the future).
   - **The Paine book**: Lucien notices English print. Béranger takes the
     book — *"I will keep it for after the war. Paper burns; so do men."*
     (`paine_kept` — the object returns in a later chapter either way.)
   - **Béranger's warnings** and Freeman's counter-pressure, then the
     branch: Freeman leaves tonight by Lucien's fast route and wants
     Travis along. **The choice: go with Lucien, or stay with Béranger.**
3. **ch4_break** — one scene, two flows on `ch4_took_fast_route`:
   - **Capture path** (trusted Lucien): the rendezvous is a courtyard;
     the car that arrives is the wrong kind. Hood, cell, and the **Voss
     interview** — quiet, procedural, no fail state. He knows Boyd's name
     before Travis gives it; what else he knows for *certain* scales with
     exposure. He quotes the Paine book. He names Pat Costa — "We have
     the waist gunner" — and lets the ambiguity do the work. Ends with a
     transfer order east and a card. Flags: `ch4_captured`, `met_voss`.
   - **Escape path** (trusted Béranger): the raid comes anyway — Freeman's
     route was watched back to the address. Boots on the stairs at night;
     Béranger's drilled contingency: *"The window. The plank. The roof.
     You do not look down and you do not wait for me."* Rooftop traverse
     over the blackout street (plank crossing, chimney line, drop to the
     coal yard), the cost visible below: her lamp going out, the car, the
     coats. Ends at the canal with the barge contact. Flags:
     `ch4_escaped`, `beranger_taken`.
   - Both: `freeman_lost` (he is in the first car either way). Both end
     END OF CHAPTER FOUR, `chapter = 5`.

## Why no fail state here

Ch2/Ch3 taught the player that wrong answers end the game. Ch4 weaponises
that training: the wrong TRUST doesn't kill you — it reroutes your war.
The capture path is the POW-thread entry the brief asks for; Chapter 5
plans two openings (transfer east / the canal barge).

## Flags

Written: `exposure` (0–4), `ch4_took_fast_route`, `ch4_captured` /
`ch4_escaped`, `freeman_lost`, `beranger_taken`, `met_voss`,
`paine_kept`, `voss_named_pat`, `warned_freeman` (tried to stop him).
Read: `lied_document` (Lucien's third probe references the paper rumour if
it travelled), `mentioned_pat`, `kept_cover`, the trust ledger.

## New audio

`ambient/city_night` (blackout street: wind in the canyon, one far car,
a cat), `ambient/apartment_day` (muffled city, pipes, a clock),
`sfx/boots_stairs` (the raid, rising), `sfx/car_trap` (car pulls up, two
doors, unhurried), `sfx/cell_door` (iron, echo).

## Non-goals

Voss touched or fought (he only ever talks), the transfer/POW camp itself
(Ch5A), the barge journey (Ch5B), Paris landmarks (a blackout canyon is a
mood, not a postcard), stealth systems (the rooftop is scripted dread).
