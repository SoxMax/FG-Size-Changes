-- 3.5/PF modifiers to ATK & AC based on size
sizeCombatModifiers = {
    [-4]=8,
    [-3]=4,
    [-2]=2,
    [-1]=1,
    [0]=0,
    [1]=-1,
    [2]=-2,
    [3]=-4,
    [4]=-8
}

-- 3.5 Grapple mods based on size
sizeGrappleModifiers = {
    [-4]=-16,
    [-3]=-12,
    [-2]=-8,
    [-1]=-4,
    [0]=0,
    [1]=4,
    [2]=8,
    [3]=12,
    [4]=16
}

-- 3.5/PF modifiers to skills based on size (stealth & hide are twice as affected)
sizeSkillModifiers = {
    [-4]=8,
    [-3]=6,
    [-2]=4,
    [-1]=2,
    [0]=0,
    [1]=-2,
    [2]=-4,
    [3]=-6,
    [4]=-8
}

-- 3.5/PF space occupied based on size, FG doesn't support sizes below 5, so set to 0
sizeSpace = {
    [-4]=0,
    [-3]=0,
    [-2]=0,
    [-1]=5,
    [0]=5,
    [1]=10,
    [2]=15,
    [3]=20,
    [4]=30
}

-- 3.5/PF "Tall" reach based on size, FG doesn't support sizes below 5, so set to 0
sizeTallReach = {
    [-4]=0,
    [-3]=0,
    [-2]=0,
    [-1]=5,
    [0]=5,
    [1]=10,
    [2]=15,
    [3]=20,
    [4]=30
}

-- 3.5/PF "Long" reach based on size, FG doesn't support sizes below 5, so set to 0
sizeLongReach = {
    [-4]=0,
    [-3]=0,
    [-2]=0,
    [-1]=5,
    [0]=5,
    [1]=5,
    [2]=10,
    [3]=15,
    [4]=20
}
