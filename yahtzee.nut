
::DICE <- {}
LAST_ROLL <- 0

for (local i = 0; i < 5; i++)
{
	DICE[i] <- {}
	DICE[i].ent <- EntityGroup[i]
	DICE[i].value <- 5
	DICE[i].held <- false
}

REFERENCE_HEIGHT <- EntityGroup[5].GetOrigin().z

CONFIG <- {
	ROLL_TIME = 2
}

::EntFireHandle <- function(target, input, value = "", delay = 0.0, activator = null, caller = null)
{
	EntFireByHandle(target, input, value, delay, activator, caller)
}

::SetHeight <- function(ent, z)
{
	local pos = ent.GetOrigin()
	pos.z = z
	ent.SetOrigin(pos)
}

::WithinBounds <- function(point, lower, upper, axes = "xyz")
{
	foreach (axis in axes)
	{
		if (point[axis] < lower[axis] || point[axis] > upper[axis])
		{
			return false
		}
	}
	return true
}

::sqr <- function(a) {return a * a}
::dist <- function(a, b) {return sqrt(sqr(a.x - b.x) + sqr(a.y - b.y) + sqr(a.z - b.z))}

::OnBulletImpact <- function(data)
{
	local impact = Vector(data.x, data.y, data.z)
	// printl("[OnBulletImpact] Impact at " + impact)
	for (local i = 0; i < 5; i++)
	{
		if (dist(impact, DICE[i].ent.GetOrigin()) < 20)
		{
			::DICE[i].held <- !DICE[i].held
		}
	}
}

RollDice <- function() {LAST_ROLL <- Time()}
DiceRolling <- function() {return CONFIG.ROLL_TIME > (Time() - LAST_ROLL)}

CompileDice <- function()
{
	local arr = {}
	for (local i = 0; i < 5; i++)
	{
		arr[i] <- DICE[i].value
		// bubble sort !
		foreach (index, val in arr)
		{
			if (index && arr[index - 1] > val)
			{
				arr[index] = arr[index - 1]
				arr[index - 1] = val
			}
		}
	}
}

GetScoreTable <- function()
{
	local count = {}
	for (local i = 0; i < 6; i++)
	{
		count[i + 1] <- 0
	}
	local sum = 0
	for (local i = 0; i < 5; i++)
	{
		local val = DICE[i].value
		sum += val
		if (val in count)
		{
			count[val]++
		}
		else
		{
			count[val] <- 1
		}
	}
	local hands = {}
	hands.aces <- count[1]
	hands.deuces <- count[2] * 2
	hands.threes <- count[3] * 3
	hands.fours <- count[4] * 4
	hands.fives <- count[5] * 5
	hands.sixes <- count[6] * 6
	hands.threeOfAKind <- 0
	hands.fourOfAKind <- 0
	local diffNumbers = 0
	foreach (num, amt in count)
	{
		if (amt)
		{
			diffNumbers++
		}
		if (amt > 2)
		{
			hands.threeOfAKind <- sum
			if (amt > 3)
			{
				hands.fourOfAKind <- sum
			}
		}
	}
	hands.fullHouse <- 0
	if (diffNumbers == 2 && !hands.fourOfAKind)
	{
		hands.fullHouse <- 25
	}
	hands.smallStraight <- 0
	hands.bigStraight <- 0
	if ((count[3] && count[4]) && ((count[1] && count[2]) || (count[2] && count[5]) || (count[5] && count[6])))
	{
		hands.smallStraight <- 30
	}
	if ((count[2] && count[3] && count[4] && count[5]) && (count[1] || count[6]))
	{
		hands.bigStraight <- 40
	}
	hands.yahtzee <- 0
	if (diffNumbers == 1)
	{
		hands.yahtzee <- 50
	}
	hands.chance <- sum
	return hands
}

TranslateScore <- {
	aces = "Aces",
	deuces = "Deuces",
	threes = "Threes",
	fours = "Fours",
	fives = "Fives",
	sixes = "Sixes",
	threeOfAKind = "3 of a kind",
	fourOfAKind = "4 of a kind",
	fullHouse = "Full house",
	smallStraight = "Sm. Straight",
	bigStraight = "Big Straight",
	chance = "Chance",
	yahtzee = "YAHTZEE",
}

Think <- function()
{
	for (local i = 0; i < 5; i++)
	{
		local die = DICE[i]
		if (die.held)
		{
			SetHeight(die.ent, REFERENCE_HEIGHT - 32)
			EntFireHandle(die.ent, "addoutput", "color 255 0 0")
		}
		else
		{
			if (DiceRolling())
			{
				SetHeight(die.ent, REFERENCE_HEIGHT + 32)
				die.value = RandomInt(1, 6)
				local tint = " " + (50 + ((Time() - LAST_ROLL) * (200 / CONFIG.ROLL_TIME))).tostring()
				EntFireHandle(die.ent, "addoutput", "color" + tint + tint + tint)
			}
			else
			{
				SetHeight(die.ent, REFERENCE_HEIGHT)
				EntFireHandle(die.ent, "addoutput", "color 255 255 255")
			}
		}
		EntFireHandle(die.ent, "addoutput", "message " + die.value.tostring())
	}
	foreach (hand, points in GetScoreTable())
	{
		EntFire("score_" + hand, "addoutput", "message " + TranslateScore[hand] + " - " + points)
	}
}

::PrintTable <- function(tab, printfunc = printl, indent = "")
{
	foreach (k, v in tab)
	{
		if (typeof v == "table")
		{
			PrintTable(v, printfunc, indent + "   ");
		}
		else
		{
			printfunc(k + " = " + v)
		}
	}
}
