# Chapter 3 — The Line (design)

Brief §7 (draft): *movement through a chain of safehouses toward a hub city,
a tense city checkpoint sequence... Anton Voss becomes a recurring,
escalating threat.* Chapter 3 covers the first link of the chain and ends on
the far side of the city checkpoint. Voss appears — once, silently, named by
a subordinate — and never looks at you. That is the escalation: in Ch2 the
Germans were a knock at the door; in Ch3 the man hunting *you specifically*
is close enough to see.

## Beats

1. **ch3_road** — dawn, moving west with Marcel along a country road.
   A Feldgendarmerie checkpoint ahead forces you both flat, then a detour
   through the hedgerows (the Ch2 walk's grammar, in daylight — the same
   country is different country at dawn). At a crossroads calvary Marcel
   hands you to the next link: **Sylvie**, a courier who moves in plain
   sight. Marcel's goodbye is the last of him for a while. A wanted-notice
   beat: someone from Paris is asking about *one* airman off that bomber —
   the first hint the paper made Travis special. If `lied_document`,
   Étienne's word travelled the line ahead of you and Sylvie's greeting is
   colder; `doubted_willis` earns a dry "Étienne says your ears work."
2. **ch3_safehouse** — the back room above Sylvie's shop in a small town.
   Daylight confinement: stay away from the window, learn the plan (papers
   for the train; the city; the next line). The radio beat: BBC static and
   *messages personnels*. Then the close call — a street sweep, boots and
   knocking working down the row of doors, watched through the curtain gap;
   they take the neighbour instead. Dusk: leave for the station.
3. **ch3_checkpoint** — the station forecourt at dusk. A queue, a lamp, two
   Feldgendarmen at a table, and a man in a long coat standing apart,
   watching faces, saying nothing. You are Jean Caillet, deaf and mute. The
   pressure dialogue is **behavioural**: the right answers are the ones
   where you do nothing — keep your eyes on your shoes when the official
   barks German, do not react when a guard drops a case behind you, hand
   over papers only when the table is tapped. Reacting like a hearing man
   accrues suspicion; `lied_document` adds one extra hard question.
   Suspicion ≥ 2 = arrest: fade, a card, retry with varied phrasings (the
   Ch2 fail/retry machinery, tighter). Passing walks you through the gate
   past the coat — a subordinate's voice, off: *"Herr Kriminalkommissar
   Voss—"* — and into the crowd. End cards; `chapter = 4`.

## Fail state

Checkpoint only. `game_over` card: "Jean Caillet could hear after all." —
retry from ch3_checkpoint with `attempt_ch3_checkpoint` varying every
question's phrasing and order of hazards.

## Trust flags consulted

`lied_document` (colder line, extra checkpoint question),
`doubted_willis`/`vouched_willis` (Sylvie's greeting), `trust_etienne`.
New flags written: `trust_sylvie`, `kept_cover`, `ch3_complete`,
`saw_voss` (always true after the checkpoint — Ch4 reads it).

## New audio slots

`ambient/town_day` (shop-room quiet: street murmur, a cart, church bell),
`ambient/station_dusk` (crowd murmur, steam hiss, a far whistle),
`sfx/radio_static` (BBC drift: static, heterodyne whine, time pips),
`sfx/stamp_thunk` (the rubber stamp hitting papers).

## Non-goals

Voss's face or voice (a coat, a name, someone else's deference), the train
ride itself (Ch4 opens on it), the betrayal branch and POW path (Ch4+),
stealth systems (sweep and checkpoint are scripted dread, not sim).
