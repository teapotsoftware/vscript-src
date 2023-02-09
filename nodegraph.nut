
::p <- ScriptPrintMessageChatAll;
p("Node Graph out of date. Rebuilding...");

StaticNodeNames <- [
	"staticnode_*"
];

DynamicNodeNames <- [
	"dynamicnode_*",
	"player"
];

CachedStaticNodeGraph <- {};
CachedDynamicNodeGraph <- {};
::CombinedNodeGraph <- {};

Sqr <- function(n) {return n * n;}
DistToSqr <- function(v1, v2) {return Sqr(v1.x - v2.x) + Sqr(v1.y - v2.y) + Sqr(v1.z - v2.z);}
IsClearLOS <- function(v1, v2) {return TraceLine(v1, v2, NULL).tointeger() == 1;}

// three space indentation, very based
::PrintTable <- function(tab, printfunc = print, indent = "", prefix = )
{
	foreach (k, v in tab)
	{
		if (typeof v == "table")
		{
			PrintTable(v, printfunc, indent + "   ");
		}
		else
		{
			printfunc(v)
		}
	}
}

BuildNodeGraphPls <- function(nodename)
{
	ret <- {};
	ent <- NULL;
	while ((ent = Entities.FindByName(ent, nodename)) != null)
	{
		local tab = {};
		tab.name = ent.GetName();
		tab.pos = ent.GetOrigin();
		tab.connections = []; // do this once we're done
		ret[name] = tab;
		CombinedNodeGraph[name] = tab;
	}
	foreach (i, node in ret)
	{
		foreach (j, subnode in CombinedNodeGraph)
		{
			if (i == j) {continue;}
			if (IsClearLOS(node.pos, subnode.pos) && !(subnode.name in node.connections))
			{
				node.connections.push(subnode.name);
			}
		}
	}
	return ret;
}

BuildStaticNodeGraph <- function()
{
	CachedStaticNodeGraph <- BuildNodeGraphPls("staticnode*");
}

BuildDynamicNodeGraph <- function()
{
	CachedDynamicNodeGraph <- BuildNodeGraphPls("dynamicnode*");
}

BuildCombinedNodeGraph <- function()
{
	// assume we've built static graph at least once
	CombinedNodeGraph <- CachedStaticNodeGraph;
	foreach (i, node in BuildDynamicNodeGraph())
	{
		CombinedNodeGraph[i] = node;
	}
}

GetNearestNode <- function(ent, checkLOS = true)
{
	ourpos <- ent.GetOrigin();
	nearest <- NULL;
	dist <- 0;
	foreach (i, node in CombinedNodeGraph)
	{
		if ((nearest == NULL || DistToSqr(ourpos, node.pos) < dist) && (IsClearLOS(ourpos, node.pos) || !checkLOS))
		{
			nearest <- i;
			dist <- DistToSqr(ourpos, node.pos);
		}
	}
	return nearest;
}

IsValidNode <- function(name)
{
	return typeof CombinedNodeGraph[name] == "table";
}

::VisualizeNode <- function(name)
{
	if (!IsValidNode(name)) {return;}
	node <- CombinedNodeGraph[name];
	foreach (connection in node.connections)
	{
		DebugDrawLine(node.pos, CombinedNodeGraph[connection].pos, 255, 0, 255, false, 8);
	}
}

::VisualizeNodes <- function()
{
	foreach (name, node in CombinedNodeGraph)
	{
		VisualizeNode(name);
	}
}

// peter moment
OnPostSpawn <- BuildStaticNodeGraph;
Think <- BuildCombinedNodeGraph;

/*
FindEntities <- function(ent, name)
{
	ret <- Entities.FindByClassname(ent, name);
	if (ret == NULL)
	{
		return Entities.FindByName(ent, name);
	}
	return ret;
}

BuildNodeGraphFromNameTable <- function(names)
{
	ret <- [];
	for (local i = 0; i < names.len(); i++)
	{
		ent <- NULL;
		while ((ent = Entities.FindByClassname(ent, names[i])) != null)
		{
			 ret[ent.GetName()] = {};
		}
		while ((ent = Entities.FindByName(ent, names[i])) != null)
		{

		}
	}
}
*/
