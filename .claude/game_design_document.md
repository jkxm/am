# Game Design Document — Combat & Core Loop

## Vision

A monster-hunting action game set in a massive vertical tower. Commitment-based weapon combat where vertical positioning is a core combat axis alongside timing and spacing. Hunt monsters, claim their gear, build your identity, and climb higher. Easy to pick up, hard to master.

---

## Core Inspirations

- Monster Hunter combat depth, gameplay loop, and weapon identity
- Monster Hunter Rise wirebug verticality (expanded)
- Monster Hunter Generations Ultimate zone-based map design
- Fighting game resource mechanics (GGST Tension Gauge, SF6 Drive Gauge)
- Elden Ring gear drops and build expression
- Dark Souls targeted drops (e.g., tail cuts for unique weapons)

---

## Combat Pillars

1. **Commitment-based combat** — Attacks have weight and animation lock. Every action is a decision.
2. **Deep weapon identity** — Each weapon class plays like its own game with unique movesets, rhythms, and skill ceilings.
3. **Verticality through positioning** — Elevation relative to the monster is a core combat axis.
4. **Monster-driven verticality** — The monster dictates vertical play through its moveset, threat zones, and phase shifts. The player reads and responds.

---

## Resource System

### Primary: Stamina

The universal resource governing base actions.

**Stamina actions:**
- Dodge
- Sprint
- Wall run (drains like sprinting)
- Block (weapon-dependent)
- Enhanced actions as backup when secondary resource is empty

**Free actions (animation commitment only):**
- Attack
- Walk
- Sheathe / unsheathe
- Wall cling (stationary on wall — free, recovers stamina, but player is vulnerable)

### Secondary: Enhanced Resource

A separate meter for improved movement and expanded combat options. Inspired by fighting game gauges.

**Replenishment:**
- Slow automatic regeneration at all times
- Faster regeneration from landing hits (aggression incentive)

**When empty:**
- Enhanced actions are still available but cost stamina instead
- Creates high-risk, high-reward moments — spending last stamina on a big play means no dodge afterward

**Enhanced resource actions:**
- Fast vault, launch, aerial reposition
- Expanded weapon-specific moves (specials, gap closers, combo extensions)

---

## Movement

### Ground
- Walk — free
- Sprint — stamina drain

### Vertical
- Wall run — stamina drain (similar to sprinting)
- Wall cling — free, recovers stamina, player is vulnerable (sitting duck)
- Enhanced vertical movement (launch, vault, fast reposition) — secondary resource, stamina as backup

### Dodge (One Button, Context-Dependent)
Dodge is purely defensive repositioning, separate from movement actions.

- **Ground roll** — short distance, generous i-frames, fast recovery. Safest and most reliable.
- **Wall dash** — covers more distance along the wall, slightly fewer i-frames, keeps player on wall. Tighter timing.
- **Air dash** — directional, narrow i-frame window, allows trajectory change. Hardest to master, highest skill expression.

Natural difficulty curve: ground is forgiving, wall is intermediate, air is high risk.

---

## Vertical Combat — Two Layers

### Micro-Repositioning (Moment to Moment)
- Small elevation changes mid-combat
- Hop onto a rock to reach the head, drop off a ledge to dodge a sweep
- Quick, tactical, woven into weapon rhythm
- Rewards map knowledge — using nearby terrain features constantly

### Macro-Repositioning (Phase Shifts)
- Monster transitions to a new vertical zone (climbs to a nest, dominates multiple levels)
- Whole fight context changes — new arena, new footing, new rules
- Forces player to ascend, descend, or find safe altitude

### Skill Expression
- Skill floor: react to macro phase shifts as they happen
- Skill ceiling: constant micro-positioning means you're never out of position when a macro shift occurs
- Reading a phase transition before it happens is the highest-level play

---

## Weapon Design Rules

- Each weapon has a **distinct core mechanic**
- All attacks either directly **feed into** the mechanic or **build toward a large payoff**
- The mechanic is **position-agnostic** — works the same grounded, on walls, or airborne
- Attacks are **context-dependent** — different moves per position, but all serve the same mechanic
- Vertical advantage is **tactical** (access, openings, safety) not **mechanical** (no artificial damage bonuses for elevation)
- A grounded master is as effective as an aerial master — they solve the fight differently
- Input scheme and complexity TBD per weapon (deferred to weapon design phase)
- **Easy to pick up, hard to master** — new players feel effective in minutes, veterans still learning after dozens of hours

### Weapon Justification Framework

A weapon class earns its place in the roster if it is distinct on at least three of five axes:

1. **Core mechanic identity** — does it have a unique build-and-payoff loop?
2. **Rhythm and pacing** — does it occupy a unique tempo in combat?
3. **Relationship with vertical space** — does it move through and fight in vertical space differently?
4. **Stamina and resource profile** — does it manage the two resources differently?
5. **Risk/reward positioning** — where does it sit on the commitment spectrum? How does it trade using the armor system?

If two weapons can't be clearly distinguished on at least three axes, they should be merged.

### Starting Roster

**Heavy Weapon (Greatsword Archetype)**
- **Core mechanic:** charge and commit. Build up to massive single hits. Payoff is one devastating strike.
- **Rhythm:** slowest in the roster. Long windups, huge recovery. Every swing is a bet.
- **Vertical:** gravity is your friend. Aerial drops multiply commitment — launch up, time the fall, land a massive hit. Miss from height and recovery is brutal. Least mobile weapon vertically.
- **Resource:** high stamina cost on defensive actions from dodging out of long recoveries. Secondary resource fuels biggest charge levels or armored approaches.
- **Risk/reward:** maximum commitment, maximum payoff. Wants to trade through armor constantly. When armor is gone, the scariest weapon to play.

**Bo Staff (Boomstick)**
- **Core mechanic:** explosive charge management. One end of the staff detonates. Every charge is a choice — spend on detonation (damage) or propulsion (movement). Constant economy of "blow up or blast off."
- **Rhythm:** mid tempo with burst moments. Staff combos flow at moderate pace, detonations create sudden spikes of damage or repositioning.
- **Vertical:** propulsion gives it a unique vertical vocabulary. Blast upward, launch off walls, propel into diving attacks. Vertical movement is built into the weapon's resource, not just universal systems.
- **Resource:** potentially low stamina reliance since propulsion replaces some movement. Charge management is the primary mental tax — spend on damage and you might not have the propulsion to escape.
- **Risk/reward:** medium commitment on normal strikes, high on detonations. Armor up means spend charges offensively. Armor gone means save charges for escape.

**Dual Impact Arms / Great Shield (Mode Switcher)**
- **Core mechanic:** kinetic energy storage and release. Split mode is an aggressive brawler landing impact hits that build energy. Combine into shield mode to block and store energy from incoming attacks. Release stored energy in a massive burst. Builds from both dealing AND receiving damage.
- **Rhythm:** two tempos in one weapon. Split mode is aggressive and mid-paced. Shield mode is reactive and patient. The burst is the punctuation. Players constantly read the fight to decide which mode to use.
- **Vertical:** split mode is mobile, can chase monsters up walls and fight aerially. Shield mode is grounded and planted. Mode switching creates vertical decisions — stay aggressive in the air or drop down and absorb? Transitioning between modes could itself be an attack.
- **Resource:** kinetic energy is a unique third resource on top of stamina and secondary. Split mode builds it through offense, shield mode through defense. Both paths feed the same payoff.
- **Risk/reward:** split mode is aggressive but unguarded. Shield mode is safe but not dealing sustained damage. Burst is maximum commitment — spending everything stored. Most complex weapon with highest skill ceiling. New players stick to one mode, veterans switch fluidly mid-combo.

**Chain Blade (Death by a Thousand Cuts)**
- **Core mechanic:** snowball momentum through sustained aggression. Consecutive hits build a multiplier or state. Plant stakes on monster limbs while attacking — hit staked limbs for bonus damage or consume stakes to topple the monster. Constant triage of where to place and when to cash in.
- **Rhythm:** fastest in the roster. Relentless, flowing, never stopping. High APM with constant micro-decisions about stake placement while maintaining momentum.
- **Vertical:** most unique in the roster. The chain allows swinging along the monster itself — the monster IS your vertical terrain. A climbing monster doesn't create distance, it creates opportunity. While other weapons use the map, this weapon uses the monster's body.
- **Resource:** armor is everything — keeps momentum chain alive through incidental hits. Stamina fuels constant movement along the monster. Secondary resource could fuel stake consumption for topples. Most armor-dependent weapon in the roster.
- **Risk/reward:** low risk per hit, massive risk in sustained commitment to being attached to the monster. Most exposed weapon because optimal play is riding the thing trying to kill you. Losing momentum is the biggest punishment.

---

## Damage System

### Dealing Damage

**Base damage:**
- Flat damage regardless of where you hit the monster
- No bouncing, no bad targets — always making progress

**Transforming weak points:**
- Weak points are not static — they move, appear, and change during the fight
- **State-driven** — monster performs a specific attack, a weak point opens briefly (e.g., throat exposed during fire breath)
- **Damage-driven** — player creates weak points by focusing attacks (break armor plating, crack shell, sever parts)
- **Phase-driven** — weak points shift as the monster changes phases
- Difficult to hit but massively rewarding

**Conditional bonuses:**
- Hitting a weak point or specified area during a major attack animation
- Doing enough damage to interrupt an attack
- Destroying parts that affect enemy combat behavior
- Terrain effects and environmental plays

**Part destruction:**
- Functional, not cosmetic — breaking parts changes monster behavior
- Break a wing: aerial sweep removed from moveset
- Crack a horn: charge tracks worse
- Player is strategically disabling the monster, not just shortening the fight
- **Dual purpose:** in-fight tactical advantage AND targeted gear drops (see Gear System)

### Taking Damage

**Armor layer:**
- Absorbs damage without interrupting the player
- Prevents stagger — allows attack animations to complete through hits
- Does NOT prevent status effect buildup
- Does NOT prevent environmental effects

**Armor restoration:**
- Armor cannot be used until **fully recovered** — it's either up or it's not, no partial protection
- **Passive regeneration** — armor slowly recovers on its own at all times
- **Accelerated by combat** — attacking, using core weapon mechanics, and items speed up recovery
- **Damage does not reset recovery progress** — armor is always coming back, getting hit just costs health
- Creates clear fight phases: lose armor → vulnerable period → work to recover → armor returns → aggression resumes

**Health layer:**
- Traditional system once armor is depleted
- Hits interrupt and stagger
- Vulnerable to all damage, status, and environmental effects
- Healed through consumable items

**Item use rules:**
- **Items can only be used while grounded** — no healing on walls or in the air
- Creates survival cost for vertical aggression — must disengage and descend to heal
- Monsters that dominate vertical space become more threatening because safe ground is harder to reach
- Adds natural fight rhythm: aggressive vertical phase → disengage to ground → heal and recover → re-engage

**Natural fight rhythm:**
- Armor up → aggressive, trading blows, committing to big attacks
- Armor thinning → more selective about trades
- Armor gone → every hit matters, tension peaks
- Armor restored → aggression returns

---

## Monster Threat Model

Monsters have three categories of threat:

### Direct Damage
- Chips armor, threatens health
- Small fast attacks wear armor over time
- Big telegraphed attacks chunk both armor and health
- Tests resource management

### Status Effects and Crowd Control
- Poison, stun, paralysis, knockdown, etc.
- Build up regardless of armor state
- Deny player options, force adaptation
- Tests adaptability

### Environmental Effects
- Floods areas, sets ground on fire, collapses ledges
- Affect everyone regardless of armor
- Deny positioning and reshape the fight space
- Tests positioning and map knowledge

**Armor interaction rules:**
- Armor blocks damage and stagger
- Armor does NOT block status effects or environmental effects
- Players can never fully brute-force through a fight on armor alone

---

## Monster Design Principles

### Core Principles
- Monsters create **shifting vertical threat and safety zones** that players must read
- Monsters have **territorial anchors** in vertical space rather than random fleeing
- Monster moveset must **punish wall clingers** (charges, projectiles, wall scrapes)
- Monsters need moves that threaten both armor and health differently
- Part destruction changes monster behavior and available attacks

### Monster Tiers (Not Every Monster Needs Every System)

**Tier 1 — Common Monsters**
- Solid ground combat with basic vertical behavior (climb or jump, but don't live vertically)
- 2-3 breakable parts with standard destruction effects
- One or two behavioral reactions
- Phase-driven weak points only (shift at health thresholds)
- No environmental reshaping
- Fastest to design, animate, and implement
- Fills out floors and provides farming variety

**Tier 2 — Signature Monsters**
- Full vertical movement vocabulary — defines how a floor feels
- 3-4 breakable parts with meaningful combat changes
- Phase-driven AND state-driven weak points (specific attacks expose vulnerability)
- Environmental effects as a signature ability
- Multiple behavioral reactions
- One or two per floor — the fights players remember and farm

**Tier 3 — Bosses and Endgame**
- Every system at full depth
- Complex phase shifts with vertical territory changes
- All three weak point types (phase, state, and damage-driven)
- Environmental reshaping as a core part of the fight
- Full reactive behavior tree
- One per major progression milestone
- Justifies heavy design investment as pinnacle content

### Shared Skeletons and Behavior Templates
- Build base templates for monster archetypes: ground brawler, wall crawler, aerial flyer, burrower
- Each template includes pre-built vertical AI, camera solutions, and movement logic
- Individual monsters are variations with unique attacks and personality layered on top
- First monster of each archetype is expensive — subsequent ones are dramatically cheaper

### Standardized Part Destruction Effects
- **Wings break** — aerial moves weakened or removed
- **Legs break** — charges and lunges slower
- **Head breaks** — ranged attacks lose accuracy
- **Tail breaks** — sweep attacks have less range
- Specific monsters can have unique break effects on top of standards, but only for signature-defining parts
- Custom break behavior is reserved for moments that define a monster's identity

### Shared Behavioral Systems
- **Enrage and exhaustion** run on a universal system with per-monster tuning values
- Every monster gets faster/more aggressive when enraged, slower/sloppier when exhausted
- Individual monsters add one or two unique reactions (special enrage attack, unique exhaustion weak point)
- **Positional adaptation** is a tagging system — monster moves are tagged with positional effectiveness. If player is on a wall, monster prioritizes anti-wall moves from its existing moveset. No custom per-monster AI needed.

### Monster Design Pipeline
1. Pick a skeleton template (ground, wall, air, burrow)
2. Pick a tier (1, 2, or 3) — determines system depth
3. Design unique attacks and personality on top of the template
4. Assign standard part destruction effects, add custom ones only for signature parts
5. Tune universal enrage/exhaust values, add one or two unique reactions
6. Tier 2+ get transforming weak points and environmental effects
7. Tier 3 gets the full treatment

### Roster Composition Goal
- A roster of 20+ monsters where 4-5 are incredible showcase fights
- The rest are solid, fun, and efficient to produce
- Players spend most time fighting good monsters and occasionally encounter great ones

---

## Monster Hunt Arc

### Philosophy
The monster reacts to the player's efforts. Two players fighting the same monster could see completely different fight arcs depending on their approach. The fight tells a story through the monster's changing state.

### Phase Shifts (Damage Thresholds)
- Monster moves through distinct phases as health drops
- Each phase changes available attacks, vertical behavior, weak point locations, and environmental effects
- These are the macro moments that reshape the fight
- Near death: limping, retreating, desperate attacks — the monster is visibly falling apart

### Behavioral Reactions (Cumulative Pressure)
- Within any phase, the monster reacts to player actions in real time
- **Part destruction** removes or alters specific attacks
- **Sustained aggression** triggers enrage — monster becomes faster and more dangerous but exposes more weak points
- **Successful blocks, dodges, or topples** can exhaust the monster — brief vulnerability windows earned through skilled play
- **Positional adaptation** — monster adapts to player positioning habits (e.g., starts using wall-punishing moves if player stays on walls)

### Readability
- **No HP bars or state icons** — the monster's body tells the story
- **Detailed visual tells for veterans:** wounds accumulate, posture changes, broken parts visible, movement patterns shift, failed attacks during exhaustion
- **Universal signals for all players:** eye glow, aura color shifts, particle effects communicate major state changes clearly
- **Post-hunt bestiary** builds player knowledge over time — teaches what visual tells to look for

---

## Map Design Principles

- **Always vertical** — elevation is constant, not situational
- Mix of **natural** (cliffs, trees, caverns) and **constructed/fantastical** (floating ruins, massive skeletons, vertical cities) environments
- **Map knowledge is a skill** — learning terrain features and how they interact with your weapon and specific monsters
- **Destructible/changeable terrain** — monsters reshape the arena mid-fight (smash ledges, collapse caves, knock down trees)
- Environmental plays — lure monsters under overhangs, collapse bridges, use vertical shafts to bottleneck
- Certain terrain favors certain weapons organically (open canyons for ranged, dense vertical jungle for light weapons)
- **Route mastery per weapon** — fastest path through a map changes depending on weapon traversal

---

## Core Gameplay Loop

### The Short Loop (Session to Session)
1. **Prepare** — choose weapon, equip gear, select consumables and support features, choose target or floor
2. **Hunt** — fight monster using commitment-based vertical combat
3. **Harvest** — collect guaranteed random drops plus targeted part destruction drops
4. **Invest** — level gear abilities with materials
5. **Optimize** — reforge by transferring max-level skills, build-craft

### The Long Loop (Progression Arc)
- Climb the tower floor by floor
- Each floor introduces new monsters, environments, and gear
- Harder monsters demand better builds and deeper mastery
- Reach the top (endgame TBD)

### Hunt Types
- **Targeted hunts** — accept a mission for a specific monster. Focused, prepared, efficient. For when you need a specific drop.
- **Expeditions** — enter a floor freely, roam its arenas, engage monsters as you find them. Organic, improvised. For discovery, farming, and surprises.

---

## Gear System

### Philosophy
- Inspired by Elden Ring — monsters drop gear directly, not crafting materials
- Every drop is immediately usable
- Build identity through mix-and-matching pieces from different monsters
- Gear tunes existing combat mechanics rather than introducing new ones

### Gear Drops and Materials
- **First kill: random gear piece** — every first monster kill guarantees a usable armor piece from its set
- **Every kill: monster-specific materials** — subsequent hunts drop materials tied to that monster
- **Part breaks: targeted gear drops** — breaking specific parts can drop specific pieces directly, bypassing crafting cost
- Targeted drops become community knowledge — discovering what breaks yield what rewards is part of the game's culture
- Creates a meaningful hunt decision: break the wing early for tactical advantage, or wait and focus on multiple parts?
- **Monsters don't need full 5-piece sets** — small monsters drop 1-2 unique pieces, mid monsters 2-3, floor bosses may have full sets. Mix-matching is the intended build path.

### Armor Skills (Cross-Pollination)
- Each armor piece comes with a set of **level 1 abilities**
- **Armor skills own the connections between systems** — they don't touch weapon mechanics directly
- Instead, skills create synergies: "when your weapon does X, universal system Y responds"
- The same skill feels different on every weapon because it reacts to different weapon behaviors
- Skill categories: universal system tuning (stamina, armor, secondary resource, dodge, wall run, status resistance) and cross-system bridges (e.g., "armor restoration accelerates when momentum is maxed," "gain secondary resource when landing a fully charged hit")
- **Level abilities up** by investing materials for greater potency
- The build game is about emphasis — one player stacks armor restoration for brawling, another tunes secondary resource for aerial play. Same weapon, different feel.

### Reforging
- **One max-level skill can transfer** from one armor piece to another
- The **source piece is destroyed** in the process — transfers are permanent sacrifices
- Each piece can carry its native abilities plus **at most one transferred skill**
- Creates long-tail progression: maxing skills and strategically cannibalizing gear to build your ideal loadout

### Gear Progression Arc
- **Early game** — use whatever drops, learn the abilities, experiment
- **Mid game** — start leveling pieces with skills that suit your playstyle
- **Late game** — maxing skills and strategically transferring them to create optimized builds
- Old gear is never wasted — it's a future transfer candidate

---

## World Structure

### The Tower
- The game world is a massive vertical tower
- Verticality as both combat mechanic and world metaphor — you are literally climbing
- Look up to see where you're going, look down to see where you've been

### Floor Design (Hub and Spoke)
- Each floor is a **hub** with multiple interconnected **arenas**
- Each arena is a distinct environment with its own terrain, vertical features, and personality
- Inspired by MHGU zone-based map design — stacked vertically
- Mix of natural environments (forests, caves, cliffs) and fantastical spaces (floating ruins, massive creature skeletons, vertical cities)
- Lower floors lean natural, upper floors lean fantastical
- Clear enough content on a floor to unlock the next

### Arena Design
- Each arena is a reusable combat environment
- Arenas have unique vertical terrain that creates tactical variety
- Same arena plays differently with different monsters and different weapons
- Destructible/changeable terrain — monsters reshape arenas mid-fight

### Monster Territory
- Monsters inhabit specific arenas on a floor
- Monsters move between arenas in learnable patterns (not random fleeing)
- Players learn monster patrols as part of mastery

---

## Preparation Phase

### Philosophy
Preparation is a meaningful phase with multiple decisions, not just gear selection. The goal is covering gaps in your build so no loadout feels locked into one approach.

### Three Layers
1. **Loadout** — weapon and gear. Your identity and build.
2. **Consumables** — healing, buffs, utility items brought into the hunt.
3. **Support features** — systems that compensate for build weaknesses. May include NPC companions, tower infrastructure, buff stations, loadout tools. (Specifics TBD)

---

## Economy

### Philosophy
Every currency flows from hunting. Monster-specific materials are the primary economy. Players farm specific monsters for specific progression, reinforcing the connection between monsters and their gear.

### Monster-Specific Materials (Primary Currency)
- Every hunt drops materials specific to that monster
- **Dual purpose:** craft missing set pieces OR level up skills on that monster's gear
- Creates a spending tension: complete the set or deepen what you have
- Skilled part-break hunters get targeted gear drops, reducing material costs
- Every subsequent hunt against a monster is meaningful — materials are always useful

### Exchange Shop
- Convert excess monster materials into materials for other monsters
- **Conversion at a loss** — prevents bypassing targeted farming
- Exists as a safety valve for dead stockpiles, not a primary progression path
- Unlocks eventually, not available from the start

### Endgame Economy
- Endgame monster variants drop **endgame-tier materials**
- Same system, higher tier — used for bonus armor slots, weapon refinement, and endgame gear upgrades
- Endgame materials are more expensive and require broader engagement across the endgame roster

### Economy Flow
1. Hunt monster → earn monster-specific materials
2. Spend materials → craft missing gear pieces OR level existing gear skills
3. Excess materials → exchange shop for other monster materials (at a loss)
4. Endgame hunts → endgame materials for bonus slots, weapon refinement, endgame upgrades

---

## Weapon Refinement

### Philosophy
Weapon refinement owns everything specific to a weapon's core mechanic. Armor skills own the universal systems and cross-system connections. No overlap between the two — refinement makes your weapon feel different, armor skills make your character perform differently.

### How It Works
- Each weapon has an internal **subsystem with tunable parameters** tied to its core mechanic
- Players adjust these values to match their playstyle
- Refinement isn't making the weapon generically stronger — it's making it specifically yours
- Two players with the same weapon can feel completely different based on their tuning

### Per-Weapon Parameters (Examples)
- **Heavy weapon** — charge speed vs charge damage, single hit vs split release
- **Bo staff** — explosion power vs propulsion power, charge capacity vs charge recovery speed
- **Great shield** — energy storage rate vs burst damage, mode transition speed, energy gain ratio from offense vs defense
- **Chain blade** — momentum buildup speed vs decay rate, stake capacity vs stake potency

### Endgame Connection
- The subsystem exists from the start with a default tuning range
- Endgame refinement materials widen the tuning range, allowing more extreme specialization
- Endgame grind has purpose — you're earning the ability to push values further than default allows

---

## Endgame Systems

### Philosophy
Endgame provides continued motivation through challenge, expression, and build expansion. Multiple systems give different player types their own chase.

### Endgame Monster Variants
- Harder versions of existing monsters with new moves, faster phase shifts, more aggressive vertical play
- Not just stat increases — genuinely new challenges that punish optimized strategies and force adaptation
- Each endgame monster is a real test of build and skill

### Bonus Armor Slots
- Endgame monsters unlock **additional skill slots** on armor pieces
- **Capped** — limited number of bonus slots across a build (exact cap TBD)
- **Expensive** — costs more than a single monster kill to unlock. May require multiple endgame monster materials, endgame currency, or challenge completions (exact gating TBD)
- Raises the optimization ceiling without randomness — you know what you're chasing
- Every endgame monster is worth hunting at least once

### Weapon Refinement (Endgame)
- Endgame materials widen weapon tuning ranges
- Deeper investment in your weapon's subsystem
- Rewards intimate knowledge of your weapon's mechanics

### Transmog
- Inspired by MHGU — separate cosmetic appearance from stats
- Fashion becomes its own endgame chase
- Player identity and visual expression through trophy gear
- Hunt specific monsters because their gear looks incredible

### Build Expansion Arc
- Base game: armor native skills + one reforged skill per piece + default weapon tuning
- Endgame: all of the above + bonus armor slots + widened weapon refinement ranges + transmog
- The optimization ceiling expands dramatically, giving long-tail motivation

---

## Open Design Questions

*To be explored in future sessions:*

- Individual weapon input schemes, combo structures, and detailed mechanic tuning
- Additional weapon types beyond the starting four
- Weapon refinement parameter ranges and tuning details
- Secondary resource tuning (recharge rates, capacity, cost per action)
- Armor restoration tuning (passive regen rate, acceleration rates, total pool size)
- Bonus armor slot cap and gating requirements
- Consumable types, item commitment speed, and item economy
- Support feature specifics (companions, infrastructure, buffs, tools)
- Monster design specifics — individual monster concepts, skeleton templates, and tier assignments
- Monsters per floor — tier distribution and roster composition per floor
- Multiplayer and co-op considerations
- Economy tuning — exchange shop rates, material drop quantities, crafting vs leveling costs
- Specific map/environment designs per floor
- Status effect types and buildup mechanics
- Camera and readability solutions for vertical combat
- Vertical incentive — ensuring micro-repositioning feels worthwhile even when not monster-forced
- Endgame monster variant design principles
- Transmog system implementation details
- Detailed numbers and tuning