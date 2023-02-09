
IncludeScript("butil")

Train <- EntityGroup[0]
Start <- EntityGroup[1]
Dest <- EntityGroup[2]

DestPath <- 2
Target <- null
TargetPos <- Vector(0, 0, 0)
CurrentNode <- -1
TargetNode <- -1

function Think()
{
	if (!Target)
		return

	local curpos = Train.GetOrigin()
	UpdateTargetPos()

	if (IsValidPath(curpos, TargetPos, Train))
	{
		WalkTo(TargetPos)
		CurrentNode = -1
	}
	else
	{
		if (CurrentNode == -1)
		{
			CurrentNode = GetNearestNode(Train.GetOrigin())
			TargetNode = NodeGraph[CurrentNode].path[GetNearestNode(TargetPos)][0]
		}

		if (IsValidNode(TargetNode))
		{
			if (DistToSqr(curpos, NodeGraph[TargetNode].pos) <= 100)
			{
				CurrentNode = TargetNode

				local newTargetNode = GetNearestNode(TargetPos)
				if (newTargetNode != -1)
				{
					local path = NodeGraph[CurrentNode].path[newTargetNode]
					PrintTable(path)
					if (path.len() > 1)
						TargetNode = path[1]
				}
			}
			else
			{
				WalkTo(NodeGraph[TargetNode].pos)
			}
		}
	}
}

function SetTarget(target)
{
	Target = target
	CurrentNode = -1
}

function UpdateTargetPos()
{
	if ("GetOrigin" in Target)
		TargetPos = Target.GetOrigin()
	else
		TargetPos = Target
}

function WalkTo(pos)
{
	local curpos = self.GetOrigin()
	// Train.SetForwardVector(pos - curpos)
	Start.SetOrigin(curpos)
	Dest.SetOrigin(pos)
	EntFireHandle(Train, "SetSpeed", "1", 0.1)
}

function PassedPath(path)
{
	if (path != DestPath)
		return

	EntFireHandle(Train, "SetSpeed", "0")

	// Swap paths
	local tempStart = Start
	Start = Dest
	Dest = tempStart

	DestPath = (DestPath == 1) ? 2 : 1
}
