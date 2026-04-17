# Vertical Slice Prototype Plan

**Monster-Hunting Action Game — Tower Setting**
**Commitment-Based Vertical Combat**

Engine: Godot 4 • Prototype Scope • April 2026

---

## 1. Purpose & Goals

This document defines the minimum viable vertical slice required to validate the game's core combat loop. The vertical slice should answer one question: does commitment-based vertical combat against a reactive monster feel good?

> **Success Criteria:** The prototype succeeds if a player can pick up a weapon, fight a blockout monster in a vertical arena, experience the full damage cycle (armor → health → heal), and want to fight it again. Visual fidelity is irrelevant. Combat feel is everything.

Everything in this document is scoped to answer that question. Systems that don't contribute to validating combat feel are explicitly deferred.

---

## 2. Toolchain & Pipeline

### 2.1 Engine

Godot 4 (GDScript). Chosen for existing developer experience, fast iteration speed, and text-based scene files that enable AI-assisted development via Claude Code.

### 2.2 Player Character

- Mixamo Y-Bot as the base rigged humanoid
- Locomotion animations sourced from Mixamo's library (walk, run, sprint, dodge rolls, jump, wall interactions)
- Weapon attack animations sourced from Mixamo where possible (greatsword swings, staff strikes) and supplemented with Cascadeur for custom attacks
- Import pipeline: Mixamo FBX → Godot import with skeleton retarget → AnimationLibrary

### 2.3 Monster

- Blockout construction: hierarchical CSGBox3D nodes parented to a root Node3D
- No skeleton or rig required — animations driven by transform tweens (Tween class) and AnimationPlayer tracks
- Color-coded body parts: red (hitbox during attack), yellow (active weak point), blue (breakable part), green (safe)
- Claude Code scaffolds the full monster scene, behavior tree, state machine, and attack library

### 2.4 Arena

- Godot CSGMesh3D and StaticBody3D primitives for terrain blockout
- Walls, platforms, ledges, and ramps built from box and cylinder primitives
- No imported meshes needed — everything constructable in-engine or via code

### 2.5 AI-Assisted Development

Claude Code is the primary implementation accelerator. Its strengths map directly to this prototype's needs: Godot .tscn scene files, GDScript state machines, behavior trees, combat frame data, and animation state machine wiring are all text-based authoring tasks. The developer provides design intent and feel feedback; Claude Code provides implementation velocity.

---

## 3. Player Systems

### 3.1 Movement

| System / Feature | Priority | Scope Notes |
|---|---|---|
| Ground locomotion (walk, sprint) | **CRITICAL** | Base movement. Stamina drain on sprint. |
| Gravity and falling | **CRITICAL** | Required for vertical play. |
| Jump / basic vault | **CRITICAL** | Reach elevated terrain. |
| Wall run | **HIGH** | Stamina drain. Core vertical traversal. |
| Wall cling | **HIGH** | Free, recovers stamina, vulnerable state. |
| Enhanced movement (launch, vault) | MEDIUM | Secondary resource cost. Test risk/reward. |

### 3.2 Dodge System

| System / Feature | Priority | Scope Notes |
|---|---|---|
| Ground roll | **CRITICAL** | Generous i-frames, short distance, fast recovery. |
| Wall dash | **HIGH** | Fewer i-frames, maintains wall state. |
| Air dash | MEDIUM | Narrow i-frame window. Hardest to master. |

> **Design Validation:** The three-context dodge is a core differentiator. The vertical slice must prove the natural difficulty curve: ground is forgiving, wall is tighter, air is punishing. If all three don't feel distinct, revisit i-frame windows and recovery values.

### 3.3 Resource System

| System / Feature | Priority | Scope Notes |
|---|---|---|
| Stamina (drain, regen, empty state) | **CRITICAL** | Governs dodge, sprint, wall run, block. |
| Enhanced resource (meter, regen) | **HIGH** | Separate gauge. Slow passive + hit-based regen. |
| Stamina fallback when enhanced empty | **HIGH** | High-risk moments. Core tension mechanic. |
| HUD for both resources | **CRITICAL** | Temporary debug UI is fine. |

### 3.4 Weapon — Heavy Weapon (Single Weapon for Slice)

The heavy weapon (greatsword archetype) is the recommended starting weapon for the vertical slice. Its slow, commitment-heavy rhythm makes every frame data decision visible and testable. If commitment combat feels good with the slowest weapon, faster weapons will inherit that foundation.

| System / Feature | Priority | Scope Notes |
|---|---|---|
| Basic 3-hit combo | **CRITICAL** | Windup, active, recovery per swing. Animation lock. |
| Charge attack | **CRITICAL** | Core mechanic — build to massive single hit. |
| Aerial drop attack | **HIGH** | Gravity multiplies payoff. Signature vertical move. |
| Cancel windows | **CRITICAL** | Defines commitment feel. When can you dodge out? |
| Hit feedback (hitstop, screen shake) | **CRITICAL** | Sells the weight. Non-negotiable for feel. |
| Sheathe / unsheathe | MEDIUM | Affects sprint and item use flow. |

> **Animation Source:** Mixamo "greatsword" and "two handed sword" searches provide heavy swing animations. Import 4–6 clips: idle, two swing variants, overhead slam, charge windup pose, and a recovery stumble. Layer combat metadata (hitbox activation frames, cancel windows, damage values) in Godot via AnimationPlayer call method tracks.

### 3.5 Damage — Taking Hits

| System / Feature | Priority | Scope Notes |
|---|---|---|
| Armor layer (absorbs without stagger) | **CRITICAL** | Enables trading. Core fight rhythm. |
| Armor depletion → health vulnerability | **CRITICAL** | Stagger on hit when armor is down. |
| Armor passive regeneration | **CRITICAL** | Always recovering. Defines fight phases. |
| Armor regen acceleration from combat | **HIGH** | Rewards aggression during vulnerable phase. |
| Hit reactions (stagger anims) | **HIGH** | Must read differently from armored hits. |
| Health + healing items (grounded only) | **HIGH** | Creates survival cost for vertical aggression. |

> **Design Validation:** The armor → vulnerable → recovery cycle is the heartbeat of every fight. The vertical slice must prove this rhythm feels natural and creates the intended tension arc: aggressive → cautious → desperate → aggressive again.

---

## 4. Monster — Tier 1 Ground Brawler

The vertical slice monster is a Tier 1 ground brawler: solid ground combat with basic vertical behavior. This is the simplest monster archetype and the cheapest to build, but it must be complex enough to validate the player's full combat toolkit.

### 4.1 Blockout Construction

- Hierarchical node tree: root → torso → head, arms (x2), legs (x2), tail
- Each body part is a separate CSGBox3D with its own Area3D hitbox collider
- Color-coded materials swap at runtime to signal state (idle, attacking, vulnerable, broken)
- Scale and proportion communicate archetype: wide low torso, thick legs, relatively small head (hard to reach, incentivizes positioning)

### 4.2 Attacks and Behavior

| System / Feature | Priority | Scope Notes |
|---|---|---|
| Telegraphed melee swipe | **CRITICAL** | Windup is readable. Tests player dodge timing. |
| Ground slam (area denial) | **CRITICAL** | Forces vertical repositioning. |
| Charge attack | **HIGH** | Punishes passive play and wall clingers. |
| Tail sweep (low) | **HIGH** | Tests micro-repositioning (jump over it). |
| Idle / patrol behavior | MEDIUM | Wander, look around, return to territory. |
| Enrage state (faster, more aggressive) | **HIGH** | Validates enrage/exhaust universal system. |
| Exhaustion window | **HIGH** | Brief vulnerability earned through pressure. |

### 4.3 Damage — Dealing to Monster

| System / Feature | Priority | Scope Notes |
|---|---|---|
| Base flat damage on any hit | **CRITICAL** | Always making progress. No bouncing. |
| Phase-driven weak points | **CRITICAL** | Shift at health thresholds. Yellow highlight. |
| 2 breakable parts (head, tail) | **HIGH** | Head break → charge tracks worse. Tail break → sweep range reduced. |
| Part damage tracking per limb | **HIGH** | Accumulate damage to trigger break. |
| Visual damage feedback on monster | **HIGH** | Material swap on damaged/broken parts. |

### 4.4 Phase Shifts

The monster should have two distinct phases to validate the phase shift system:

1. **Phase 1 (100–50% HP):** Standard ground combat. Melee swipes, tail sweeps, occasional slam. One weak point on the belly (phase-driven).
2. **Phase 2 (50–0% HP):** Enraged. Faster attacks, adds charge attack, climbs to an elevated position briefly (forcing player to ascend). Weak point shifts to the back. Near death: visibly limping, attacks have longer recovery, exhaustion windows are more frequent.

### 4.5 AI Architecture

The monster AI should be built as a reusable template that future monsters can inherit:

- **State machine:** Idle → Alert → Combat → Phase Transition → Enraged → Exhausted → Dying
- **Attack selection:** Weighted random from available pool, with positional tags. If player is on wall, weight charge attack higher.
- **Cooldown system:** Per-attack cooldowns prevent repetition.
- **Phase controller:** Health threshold triggers, weak point activation, attack pool changes.

> **Claude Code Target:** The entire monster — node hierarchy, state machine, attack definitions, phase controller, part destruction, and AI behavior — is fully implementable by Claude Code. Describe each attack as timing data (telegraph duration, active frames, recovery, hitbox dimensions, damage values) and let Claude Code build the implementation. Iterate on feel by adjusting values through conversation.

---

## 5. Arena — Single Vertical Blockout

One arena is sufficient for the vertical slice. It must contain enough vertical variety to test the full movement and combat toolkit.

### 5.1 Required Terrain Features

- **Flat ground floor:** Primary fight space. Open enough for the monster to use its full moveset.
- **Elevated platforms (2–3 tiers):** Reachable by jump, wall run, or enhanced movement. Test micro-repositioning.
- **Climbable walls:** At least two wall surfaces for wall run and wall cling testing.
- **A high perch or ledge:** For aerial drop attack testing. Must have risk/reward — reaching it costs time and resources.
- **Tight spaces and open spaces:** The monster should feel different to fight in cramped vs open areas within the same arena.
- **One destructible element:** A platform or wall the monster can smash. Validates terrain reshaping.

### 5.2 Construction Approach

Build entirely from Godot CSG primitives and StaticBody3D nodes. Gray-box with subtle color variation to distinguish floor, walls, and platforms. No textures needed. Collision shapes must be precise — wall run detection depends on clean wall normals and consistent surface tagging.

---

## 6. Combat Feel Infrastructure

These systems are invisible but make or break the prototype. They are as important as any gameplay system.

| System / Feature | Priority | Scope Notes |
|---|---|---|
| Hitstop (freeze frames on hit) | **CRITICAL** | 50–120ms pause on contact. Sells impact. |
| Screen shake | **CRITICAL** | Scaled to damage. Subtle on light, heavy on charged. |
| Hit particles / flash | **HIGH** | Simple spark effect + white flash on target. |
| Camera system (3D orbit + vertical) | **CRITICAL** | Must handle vertical combat without disorienting. |
| Camera lock-on to monster | **CRITICAL** | Soft lock that tracks monster during combat. |
| Input buffering | **CRITICAL** | Queue next input during recovery. Prevents eaten inputs. |
| Damage numbers (debug) | MEDIUM | Floating numbers for tuning. Not final UI. |
| Sound effects (placeholder) | **HIGH** | Impact sounds, whoosh on swings, monster grunts. Sells commitment weight. |

> **Non-Negotiable:** Hitstop, screen shake, and input buffering are not polish — they are core to commitment combat feel. A prototype without these will feel wrong regardless of how correct the underlying systems are. Implement these before tuning any damage values.

---

## 7. Explicitly Deferred

The following systems from the game design document are intentionally excluded from the vertical slice. They are important to the full game but do not contribute to validating core combat feel.

### 7.1 Deferred Systems

- **Gear system and drops:** No loot, no armor skills, no reforging. Combat effectiveness is hardcoded for the prototype.
- **Weapon refinement:** Weapon parameters are fixed. Tuning is done by the developer, not the player.
- **Economy and materials:** No currencies, no crafting, no exchange shop.
- **Additional weapons:** Only the heavy weapon. Bo staff, great shield, and chain blade come after combat feel is validated.
- **Preparation phase:** No consumable selection, no loadout screen, no support features.
- **World structure and tower:** Single arena only. No floors, no hub, no progression.
- **Multiplayer:** Single player only for the vertical slice.
- **Endgame systems:** No bonus slots, no transmog, no endgame variants.
- **Status effects and crowd control:** Monster deals direct damage only. No poison, stun, or paralysis.
- **Environmental effects:** No fire, flood, or area denial beyond the monster's own attacks.
- **Bestiary and hunt tracking:** No metagame progression or monster knowledge systems.
- **Hunt types:** No expedition mode, no mission select. Direct-to-fight.

### 7.2 Why This Scope

The vertical slice tests one thing: does the combat loop feel good? The answer to that question determines whether the rest of the game is worth building. Gear, progression, economy, and world structure are force multipliers on a combat loop that works. They cannot rescue a combat loop that doesn't.

---

## 8. Implementation Milestones

Suggested build order. Each milestone produces a testable result. Earlier milestones should not be skipped — later systems assume earlier ones are working.

### Milestone 1 — Character Controller

Ground movement, jump, gravity, sprint with stamina drain. Dodge roll with i-frames. Basic camera. No combat. This milestone validates that moving around the arena feels good.

### Milestone 2 — Vertical Movement

Wall detection, wall run, wall cling, wall jump. Enhanced resource meter and enhanced movement (vault, launch). Context-dependent dodge (ground roll, wall dash, air dash with different i-frame windows). This milestone validates the three-layer movement system.

### Milestone 3 — Heavy Weapon Combat

Import Y-Bot with Mixamo animations. Basic combo, charge attack, aerial drop attack. Hitbox system, cancel windows, input buffering. Hitstop and screen shake. Attack a static target dummy (a stationary blockout with hurtboxes). This milestone validates that attacks feel weighty and committed.

### Milestone 4 — Damage Model

Player armor layer, health layer, armor regeneration, healing items (grounded only). Damage numbers for tuning. Hit reactions (armored vs unarmored). This milestone validates the armor cycle rhythm.

### Milestone 5 — Monster

Blockout ground brawler with full AI: idle, alert, combat states. 4–5 attacks with telegraphs. Hitboxes that interact with the player damage model. Part destruction (head + tail). Phase shift at 50% HP. Enrage and exhaustion. This milestone validates that fighting a reactive opponent creates the intended tension arc.

### Milestone 6 — Arena + Integration

Build the vertical blockout arena. Place the monster. Test the complete loop: enter arena, fight monster through both phases, use vertical terrain, take damage, heal, recover armor, win or lose. Iterate on tuning. This milestone is the vertical slice.

> **Iteration Is the Point:** These milestones are not waterfall phases. Expect to revisit earlier milestones as later ones reveal feel issues. The heavy weapon's cancel windows will change after you fight the actual monster. The monster's telegraph timing will change after the arena introduces vertical play. Budget time for iteration, not just implementation.

---

## 9. Key Risks

### 9.1 Camera in Vertical Combat

The camera is the single biggest technical risk. A third-person camera that handles ground combat, wall combat, and aerial combat without disorienting the player is genuinely hard. Expect to iterate extensively. Consider implementing multiple camera behaviors (ground mode, wall mode, aerial mode) that blend between contexts, mirroring the context-dependent dodge system.

### 9.2 Wall Run Detection Reliability

Wall run depends on clean collision normals and consistent surface detection. CSG primitives in Godot should provide clean normals, but edge cases (corners, angled surfaces, transitions between surfaces) will need careful handling. Build wall detection as an isolated system that can be tuned independently of movement code.

### 9.3 Mixamo Animation Integration

Godot 4's Mixamo import pipeline has improved but still requires setup for skeleton retargeting. Budget an initial session specifically for getting one animation playing correctly on Y-Bot in Godot before committing to the full animation library. Root motion handling is a key early decision — code-driven movement with animation blending is recommended for the prototype.

### 9.4 Combat Feel Subjectivity

Frame data, hitstop duration, i-frame windows, and recovery timing are all feel-driven values that resist analytical derivation. These values must be discovered through play-testing and iteration. Expose all timing values as easily editable parameters (exported variables in Godot). Consider building a simple debug overlay that shows current state, active frames, and i-frame windows in real time.