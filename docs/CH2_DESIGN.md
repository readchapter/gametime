# Chapter 2 — The Vetting (design)

Brief (§7): *Travis is questioned by the local resistance network to determine
if he's genuinely who he says he is; wrong answers can end the game. Another
evader being vetted alongside him fails and is killed, establishing stakes.
This is where the trust/dialogue system needs to really flex.*

## Beats

1. **ch2_morning** — the farmhouse, morning after. Cold early light in the
   same rooms. The family is tense: word of the crash has spread. A German
   patrol arrives at the door — Henri orders Travis to hide in the bedroom
   (against the wall, out of the window's line). The knock/search plays as a
   held-breath audio beat. `landing_bad` pays off: a bad landing means the
   patrol actually steps inside and the beat runs longer and closer.
   At dusk a resistance escort — **"Marcel"** — arrives. Henri vouches for
   the family's risk; Travis leaves with Marcel.
2. **ch2_walk** — night, the same countryside (field.tscn reuse). Travis
   follows Marcel off-road along the hedgerows. One scripted danger: a
   German truck on the road — Marcel drops Travis into the ditch as the
   headlights sweep past. Arrive at a barn on the village edge.
3. **ch2_vetting** — the barn. The network chief — **"Étienne"**, a village
   schoolmaster who taught himself English — questions two evaders by
   lantern light: Travis, and **Flight Sergeant Ray Willis**, who talks too
   much and gets details of his own story wrong (says Lancaster, later says
   Halifax). Sequence:
   - Willis is questioned first. His slip is audible to a player paying
     attention.
   - Étienne asks Travis for his read on Willis (vouch / doubt / silence —
     trust flags for later chapters; vouching for him costs suspicion).
   - Willis is walked out. One shot, off-screen. Nobody speaks of it.
   - Travis's own vetting: personal questions an infiltrator would flub
     (Hempstead; watermelon and cotton; the tail turret; Ebbets Field —
     which Travis only knows because Pat never talked about anything else).
   - They search him and find **the document fragment**. Truth ("I grabbed
     it in the chaos — I don't know what it is") reads honest; a lie is
     nearly fatal. Étienne keeps the paper. (This is the Ch3+ BIGOT thread.)
   - Pass → civilian clothes, "You move at dawn." End card. `chapter = 3`.
   - Fail (suspicion ≥ 2 at the final check, or the document lie compounding)
     → taken outside. Fade, one shot, a stark card — and retry from the barn
     with **varied question phrasings** (the replay-variation pools, live).

## Fail state (first in the game)

`SceneDirector.game_over(text)` → black, card, then reload the current beat.
Each retry increments `attempt_<dialogue_id>`; DialogueManager picks
`lines[attempt % lines.size()]`, so a retried vetting never replays
word-for-word (brief §5 replay variation, now functional).

## Dialogue system extensions (backward compatible)

- Conditions support numeric compare: `"suspicion>=2"` (flags default 0).
- Effects support increment: `{"+suspicion": 1}`.
- `branch` nodes route through the same condition parser.
- Line pools pick per attempt (see above); index 0 when no attempts flag.
- Choices may set `"autoplay": true` to steer headless runs (defaults to
  first choice otherwise); shuffle correct answers freely in data.

## Trust flags set here (consulted in Ch3+)

`doubted_willis`, `vouched_willis`, `told_truth_document`,
`lied_document`, `trust_etienne`, `landing_bad` (carried in).

## Non-goals

Voss on-screen (he is *felt* — the patrol, the truck), stealth systems
(hide/ditch beats are scripted, not systemic), hunger/fatigue, Chapter 3.
