import("pathfinder.road", "RoadPathFinder", 3);
class AutonomousInstitutions extends AIController 
{
  function Start();
}

function AutonomousInstitutions::Start()
{
  if (!AICompany.SetName("AutonomousInstitutions")) {
    local i = 2;
    while (!AICompany.SetName("AutonomousInstitutions #" + i))
      i = i + 1;
  }
  /* Forms List of All Present Towns on Map */
  local townslist = AITownList();
  /* Sort townslist by Population (high -> low) */
  townslist.Valuate(AITown.GetPopulation);
  townslist.Sort(AIAbstractList.SORT_BY_VALUE, false);
  /* Select Town with Highest Population */
  local townid_a = townslist.Begin();
  local min_dist = -1;
  local townid_b
  foreach (town, value in townslist) {
    
    
    if(townid_a == town) {
      continue;
    }
    local distance = AIMap.DistanceManhattan(AITown.GetLocation(townid_a), AITown.GetLocation(town));
    if (distance < min_dist || min_dist == -1)  {
      min_dist = distance
      townid_b = town
    } else {
      continue;
    }
    //AILog.Info(AITown.GetLocation(townid_a))
  }
  
  /* Print the names of the towns we'll try to connect. */
  AILog.Info("Going to connect " + AITown.GetName(townid_a) + " to " + AITown.GetName(townid_b));

  /* Tell OpenTTD we want to build normal road (no tram tracks). */
  AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);

  /* Create an instance of the pathfinder. */
  local pathfinder = RoadPathFinder();

  /* Set the cost for making a turn extreme high. */
  pathfinder.cost.turn = 200;

  /* Give the source and goal tiles to the pathfinder. */
  pathfinder.InitializePath([AITown.GetLocation(townid_a)], [AITown.GetLocation(townid_b)]);

  /* Try to find a path. */
  local path = false;
  while (path == false) {
    path = pathfinder.FindPath(100);
    this.Sleep(1);
  }

  if (path == null) {
    /* No path was found. */
    AILog.Error("pathfinder.FindPath return null");
  }

  /* If a path was found, build a road over it. */
  while (path != null) {
    local par = path.GetParent();
    if (par != null) {
      local last_node = path.GetTile();
      if (AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) == 1 ) {
        if (!AIRoad.BuildRoad(path.GetTile(), par.GetTile())) {
          /* An error occured while building a piece of road. TODO: handle it. 
           * Note that is can also be the case that the road was already build. */
        }
      } else {
        /* Build a bridge or tunnel. */
        if (!AIBridge.IsBridgeTile(path.GetTile()) && !AITunnel.IsTunnelTile(path.GetTile())) {
          /* If it was a road tile, demolish it first. Do this to work around expended roadbits. */
          if (AIRoad.IsRoadTile(path.GetTile())) AITile.DemolishTile(path.GetTile());
          if (AITunnel.GetOtherTunnelEnd(path.GetTile()) == par.GetTile()) {
            if (!AITunnel.BuildTunnel(AIVehicle.VT_ROAD, path.GetTile())) {
              /* An error occured while building a tunnel. TODO: handle it. */
            }
          } else {
            local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) + 1);
            bridge_list.Valuate(AIBridge.GetMaxSpeed);
            bridge_list.Sort(AIAbstractList.SORT_BY_VALUE, false);
            if (!AIBridge.BuildBridge(AIVehicle.VT_ROAD, bridge_list.Begin(), path.GetTile(), par.GetTile())) {
              /* An error occured while building a bridge. TODO: handle it. */
            }
          }
        }
      }
    }
    path = par;
  }
  AILog.Info("Done");
  AILog.Info(AIMap.GetTileX(AITown.GetLocation(townid_a)))
  AILog.Info(AIMap.GetTileY(AITown.GetLocation(townid_a)))
  /* Depot Module */
  local x_a = AIMap.GetTileX(AITown.GetLocation(townid_a));
  local y_a = AIMap.GetTileY(AITown.GetLocation(townid_a));
  local index_a = AIMap.GetTileIndex(x_a, y_a);
  /* Create Target Variables */
  local t_x
  local t_y
  local t_index
  /* Starting from the center of a town, while we can't build, find tile that's buildable*/
  if (AITile.IsBuildable(AIMap.GetTileIndex(x_a, y_a)) == false) {
    local i = 0;
    /* Look for Buildable North*/
    for (i=0; i<5; i++) {
      y_a = y_a + 1
      /* Check if tile is buildable, check if tile borders any road tiles*/
      if (AITile.IsBuildable(AIMap.GetTileIndex(x_a, y_a)) == true) {
        if (AIRoad.GetNeighbourRoadCount(AIMap.GetTileIndex(x_a, y_a)) > 0) {
          /* Suitable Tile Found, set targetcords, find side to face road */
          t_x = x_a
          t_y = y_a
          t_index = AIMap.GetTileIndex(t_x, t_y);
          AILog.Info("Suitable Tile Found at: " + t_index)
          break;
        }
      } 
    }
    /* Look for Buildable South*/
    for (i=5; i<10; i++) {
      y_a = y_a - 1
      /* Check if tile is buildable, check if tile borders any road tiles*/
      if (AITile.IsBuildable(AIMap.GetTileIndex(x_a, y_a)) == true) {
        if (AIRoad.GetNeighbourRoadCount(AIMap.GetTileIndex(x_a, y_a)) > 0) {
          /* Suitable Tile Found, set targetcords, find side to face road */
          t_x = x_a
          t_y = y_a
          t_index = AIMap.GetTileIndex(t_x, t_y);
          AILog.Info("Suitable Tile Found at: " + t_index)
          break;
        }
      }
    }
    /* Look for Buildable East*/
    for (i=10; i<15; i++) {
      x_a = x_a + 1
      /* Check if tile is buildable, check if tile borders any road tiles*/
      if (AITile.IsBuildable(AIMap.GetTileIndex(x_a, y_a)) == true) {
        if (AIRoad.GetNeighbourRoadCount(AIMap.GetTileIndex(x_a, y_a)) > 0) {
          /* Suitable Tile Found, set targetcords, find side to face road */
          t_x = x_a
          t_y = y_a
          t_index = AIMap.GetTileIndex(t_x, t_y);
          AILog.Info("Suitable Tile Found at: " + t_index)
          break;
        }
      }
    }
    /* Look for Buildable West*/
    for (i=15; i<20; i++) {
      x_a = x_a - 1
      /* Check if tile is buildable, check if tile borders any road tiles*/
      if (AITile.IsBuildable(AIMap.GetTileIndex(x_a, y_a)) == true) {
        if (AIRoad.GetNeighbourRoadCount(AIMap.GetTileIndex(x_a, y_a)) > 0) {
          /* Suitable Tile Found, set targetcords, find side to face road */
          t_x = x_a
          t_y = y_a
          t_index = AIMap.GetTileIndex(t_x, t_y);
          AILog.Info("Suitable Tile Found at: " + t_index)
          break;
        }
      }
    }
  } 
  /* Tell OpenTTD we want to build road depot. */
  //AIRoad.SetCurrentBuildType(AIRoad.BT_DEPOT);

  /* Check if Suitable Target Tile Found  */
  if ((AITile.IsBuildable(AIMap.GetTileIndex(t_x, t_y)) == true) && (AIRoad.GetNeighbourRoadCount(AIMap.GetTileIndex(t_x, t_y)) > 0)) {
    /* Try to Build Depot North */
    if ((AIMap.IsValidTile(AIMap.GetTileIndex(t_x, t_y + 1)) == true) && (AIRoad.IsRoadTile(AIMap.GetTileIndex(t_x, t_y + 1)) == true)) {
      AILog.Info("Building Road Depot at tile: " + AIMap.GetTileIndex(t_x, t_y + 1))
      AIRoad.BuildRoadDepot(t_index, AIMap.GetTileIndex(t_x, t_y + 1))
    } else {
      AILog.Info("Cannot Build Road Depot Facing North")
    }
    /* Try to Build Depot South */
    if ((AIMap.IsValidTile(AIMap.GetTileIndex(t_x, t_y - 1)) == true) && (AIRoad.IsRoadTile(AIMap.GetTileIndex(t_x, t_y - 1)) == true)) {
      AILog.Info("Building Road Depot at tile: " + AIMap.GetTileIndex(t_x, t_y - 1))
      AIRoad.BuildRoadDepot(t_index, AIMap.GetTileIndex(t_x, t_y - 1))
    } else {
      AILog.Info("Cannot Build Road Depot Facing South")
    }
    /* Try to Build Depot East */
    if ((AIMap.IsValidTile(AIMap.GetTileIndex(t_x + 1, t_y)) == true) && (AIRoad.IsRoadTile(AIMap.GetTileIndex(t_x + 1, t_y)) == true)) {
      AILog.Info("Building Road Depot at tile: " + AIMap.GetTileIndex(t_x + 1, t_y))
      AIRoad.BuildRoadDepot(t_index, AIMap.GetTileIndex(t_x + 1, t_y))
    } else {
      AILog.Info("Cannot Build Road Depot Facing East")
    }
    /* Try to Build Depot West */
    if ((AIMap.IsValidTile(AIMap.GetTileIndex(t_x - 1, t_y)) == true) && (AIRoad.IsRoadTile(AIMap.GetTileIndex(t_x - 1, t_y)) == true)) {
      AILog.Info("Building Road Depot at tile: " + AIMap.GetTileIndex(t_x - 1, t_y))
      AIRoad.BuildRoadDepot(t_index, AIMap.GetTileIndex(t_x - 1, t_y))
    } else {
      AILog.Info("Cannot Build Road Depot Facing West")
    }
  } else {
    AILog.Info("Suitable Target Tile Fails Conditions")
  }
  while (true) {
    AILog.Info("I am a very new AI with a ticker called AutonomousInstitutions and I am at tick " + this.GetTick());
    this.Sleep(50);
  }
}