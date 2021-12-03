# FG-Size-Changes
Extension for Fantasy Grounds'  3.5 and Pathfinder rulesets that adds a effects for manipulating a character's size.

**SIZE** effect will modify a player's attack, ac, cmd, cmb, fly skill, stealth skill and damage dice on weapons.  
**ESIZE** will modify a player's damage dice on weapons.

The 3.5 rules for size changes: http://www.d20srd.org/srd/combat/movementPositionAndDistance.htm#bigandLittleCreaturesInCombat  
The Pathfinder rules for size changes: https://www.d20pfsrd.com/gamemastering/combat/space-reach-threatened-area-templates?/#Creature_Sizes  
I'm using Paizo's FAQ on damage dice changes for both rulesets: https://paizo.com/paizo/faq/v5748nruor1fm#v5748eaic9t3f

| Modifier | Value | Descriptors      | Notes                 |
| -------- |:------| :----------------|:----------------------|
| SIZE     | (N)   | [bonus], [range] | Size change           |
| ESIZE    | (N)   | [bonus], [range] | Effective Size Change |

**(N)** = Only numbers supported for value attribute

**[bonus]** = alchemical, armor, circumstance, competence, deflection, dodge, enhancement, insight, luck, morale, natural, profane, racial, resistance, sacred, shield, size  
**[range]** = melee, ranged

## Examples
- Enlarge Person; SIZE: 1 size, melee
- Reduce Person; SIZE: -1 size, melee
- Lead Blades; ESIZE: 1 size, melee
- Gravity Bow; ESIZE: 1 size, ranged
