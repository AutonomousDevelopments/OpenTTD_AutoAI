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
  AILog.Info("Starting Road Module...")
  local townCount = AITown.GetTownCount()
  if (townCount < 2) {
    AILog.Info("Not Enough Towns to Build Network");
    while (true) {
      this.Sleep(50)
    }
  } else {
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
    AILog.Info("Starting Depot Module...")
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
      for (i=0; i<100; i++) {
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
      for (i=100; i<200; i++) {
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
      for (i=200; i<300; i++) {
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
      for (i=300; i<400; i++) {
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
        if (AIRoad.AreRoadTilesConnected(t_index, AIMap.GetTileIndex(t_x, t_y + 1)) == false) {
          AIRoad.BuildRoad(t_index, AIMap.GetTileIndex(t_x, t_y + 1))
        }
      } else {
        AILog.Info("Cannot Build Road Depot Facing North")
      }
      /* Try to Build Depot South */
      if ((AIMap.IsValidTile(AIMap.GetTileIndex(t_x, t_y - 1)) == true) && (AIRoad.IsRoadTile(AIMap.GetTileIndex(t_x, t_y - 1)) == true)) {
        AILog.Info("Building Road Depot at tile: " + AIMap.GetTileIndex(t_x, t_y - 1))
        AIRoad.BuildRoadDepot(t_index, AIMap.GetTileIndex(t_x, t_y - 1))
        if (AIRoad.AreRoadTilesConnected(t_index, AIMap.GetTileIndex(t_x, t_y - 1)) == false) {
          AIRoad.BuildRoad(t_index, AIMap.GetTileIndex(t_x, t_y - 1))
        }
      } else {
        AILog.Info("Cannot Build Road Depot Facing South")
      }
      /* Try to Build Depot East */
      if ((AIMap.IsValidTile(AIMap.GetTileIndex(t_x + 1, t_y)) == true) && (AIRoad.IsRoadTile(AIMap.GetTileIndex(t_x + 1, t_y)) == true)) {
        AILog.Info("Building Road Depot at tile: " + AIMap.GetTileIndex(t_x + 1, t_y))
        AIRoad.BuildRoadDepot(t_index, AIMap.GetTileIndex(t_x + 1, t_y))
        if (AIRoad.AreRoadTilesConnected(t_index, AIMap.GetTileIndex(t_x + 1, t_y)) == false) {
          AIRoad.BuildRoad(t_index, AIMap.GetTileIndex(t_x + 1, t_y))
        }
      } else {
        AILog.Info("Cannot Build Road Depot Facing East")
      }
      /* Try to Build Depot West */
      if ((AIMap.IsValidTile(AIMap.GetTileIndex(t_x - 1, t_y)) == true) && (AIRoad.IsRoadTile(AIMap.GetTileIndex(t_x - 1, t_y)) == true)) {
        AILog.Info("Building Road Depot at tile: " + AIMap.GetTileIndex(t_x - 1, t_y))
        AIRoad.BuildRoadDepot(t_index, AIMap.GetTileIndex(t_x - 1, t_y))
        if (AIRoad.AreRoadTilesConnected(t_index, AIMap.GetTileIndex(t_x - 1, t_y)) == false) {
          AIRoad.BuildRoad(t_index, AIMap.GetTileIndex(t_x - 1, t_y))
        }
      } else {
        AILog.Info("Cannot Build Road Depot Facing West")
      }
    } else {
      AILog.Info("Suitable Target Tile Fails Conditions")
    }
    AILog.Info("Starting Station Module...")
    /* Build Stations */
    /* Build Station in Town A */
    /* Set Coordinates for Town Center */
    x_a = AIMap.GetTileX(AITown.GetLocation(townid_a));
    y_a = AIMap.GetTileY(AITown.GetLocation(townid_a));
    /* Check if Town Center is Valid, Check if Town Center is Road*/
    if ((AIMap.IsValidTile(AIMap.GetTileIndex(x_a, y_a)) == true) && (AIRoad.IsRoadTile(AIMap.GetTileIndex(x_a, y_a)) == true)) {
      /* Check if Town Center is not Junction*/
      AILog.Info("Checking if Town Center is not Junction...")
      if (AIRoad.GetNeighbourRoadCount(AIMap.GetTileIndex(x_a, y_a)) == 2) {
        /* See if Neighbor Road is East */
        if ((AIMap.IsValidTile(AIMap.GetTileIndex(x_a + 1, y_a)) == true) && (AIRoad.IsRoadTile(AIMap.GetTileIndex(x_a + 1, y_a)) == true)) {
          AILog.Info("Building Station with neighbor road East")
          AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(x_a, y_a), AIMap.GetTileIndex(x_a + 1, y_a), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)
          /* See if Neighbor Road is West */
        } else if ((AIMap.IsValidTile(AIMap.GetTileIndex(x_a - 1, y_a)) == true) && (AIRoad.IsRoadTile(AIMap.GetTileIndex(x_a - 1, y_a)) == true)) {
          AILog.Info("Building Station with neighbor road West")
          AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(x_a, y_a), AIMap.GetTileIndex(x_a - 1, y_a), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW);
          /* See if Neighbor Road is North */
        } else if ((AIMap.IsValidTile(AIMap.GetTileIndex(x_a, y_a + 1)) == true) && (AIRoad.IsRoadTile(AIMap.GetTileIndex(x_a, y_a + 1)) == true)) {
          AILog.Info("Building Station with neighbor road North")
          AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(x_a, y_a), AIMap.GetTileIndex(x_a, y_a + 1), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)
          /* See if Neighbor Road is South */
        } else if ((AIMap.IsValidTile(AIMap.GetTileIndex(x_a, y_a - 1)) == true) && (AIRoad.IsRoadTile(AIMap.GetTileIndex(x_a, y_a - 1)) == true)) {
          AILog.Info("Building Station with neighbor road South")
          AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(x_a, y_a), AIMap.GetTileIndex(x_a, y_a - 1), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)
        }
      } else {
        /* Town Center is a Junction */
        AILog.Info("Town Center is Junction...")
        local i = 0
        local stationBuilt = false;
          /* Try to Find Non-Junction North */
          for (i=0; i<5 && (stationBuilt == false); i++) {
            y_a = y_a + 1
            if (AIRoad.GetNeighbourRoadCount(AIMap.GetTileIndex(x_a, y_a)) < 3 && (stationBuilt == false)) {
              t_x = x_a
              t_y = y_a
              t_index = AIMap.GetTileIndex(t_x, t_y);
              AILog.Info("Found Non-Junction North of Town Center")
              /* See if Neighbor Road is East */
              if ((AIMap.IsValidTile(AIMap.GetTileIndex(t_x + 1, t_y)) == true) && (AIRoad.IsRoadTile(AIMap.GetTileIndex(t_x + 1, t_y) ) == true) && (stationBuilt == false)) {
                AILog.Info("Neighbor Road is East")
                AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(t_x, t_y), AIMap.GetTileIndex(t_x + 1, t_y), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)
                stationBuilt = true
                break;
                /* See if Neighbor Road is West */
              } else if ((AIMap.IsValidTile(AIMap.GetTileIndex(t_x - 1, t_y)) == true) && (AIRoad.IsRoadTile(AIMap.GetTileIndex(t_x - 1, t_y)) == true) && (stationBuilt == false)) {
                AILog.Info("Neighbor Road is West")
                AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(t_x, t_y), AIMap.GetTileIndex(t_x - 1, t_y), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)
                stationBuilt = true
                break;
                /* See if Neighbor Road is North */
              } else if ((AIMap.IsValidTile(AIMap.GetTileIndex(t_x, t_y + 1)) == true) && (AIRoad.IsRoadTile(AIMap.GetTileIndex(t_x, t_y + 1)) == true) && (stationBuilt == false)) {
                AILog.Info("Neighbor Road is North")
                AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(t_x, t_y), AIMap.GetTileIndex(t_x, t_y + 1), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW);
                stationBuilt = true
                break;
                /* See if Neighbor Road is South */
              } else if ((AIMap.IsValidTile(AIMap.GetTileIndex(t_x, t_y - 1)) == true) && (AIRoad.IsRoadTile(AIMap.GetTileIndex(t_x, t_y - 1)) == true) && (stationBuilt == false)) {
                AILog.Info("Neighbor Road is South")
                AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(t_x, t_y), AIMap.GetTileIndex(t_x, t_y - 1), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)
                stationBuilt = true
                break;
              }
            } else {
              break;
            }
          }
          /* Try to Find Non-Junction South */
          for (i=5; i<10 && (stationBuilt == false); i++) {
            y_a = y_a - 1
            if (AIRoad.GetNeighbourRoadCount(AIMap.GetTileIndex(x_a, y_a)) < 3 && (stationBuilt == false)) {
              t_x = x_a
              t_y = y_a
              t_index = AIMap.GetTileIndex(t_x, t_y);
              AILog.Info("Found Non-Junction South of Town Center")
              /* See if Neighbor Road is East */
              if ((AIMap.IsValidTile(AIMap.GetTileIndex(t_x + 1, t_y)) == true) && (AIRoad.IsRoadTile(AIMap.GetTileIndex(t_x + 1, t_y)) == true) && (stationBuilt == false)) {
                AILog.Info("Neighbor Road is East")
                AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(t_x, t_y), AIMap.GetTileIndex(t_x + 1, t_y), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)
                stationBuilt = true
                break;
                /* See if Neighbor Road is West */
              } else if ((AIMap.IsValidTile(AIMap.GetTileIndex(t_x - 1, t_y)) == true) && (AIRoad.IsRoadTile(AIMap.GetTileIndex(t_x - 1, t_y)) == true) && (stationBuilt == false)) {
                AILog.Info("Neighbor Road is West")
                AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(t_x, t_y), AIMap.GetTileIndex(t_x - 1, t_y), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)
                stationBuilt = true
                break;
                /* See if Neighbor Road is North */
              } else if ((AIMap.IsValidTile(AIMap.GetTileIndex(t_x, t_y + 1)) == true) && (AIRoad.IsRoadTile(AIMap.GetTileIndex(t_x, t_y + 1)) == true) && (stationBuilt == false)) {
                AILog.Info("Neighbor Road is North")
                AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(t_x, t_y), AIMap.GetTileIndex(t_x, t_y + 1), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)
                stationBuilt = true
                break;
                /* See if Neighbor Road is South */
              } else if ((AIMap.IsValidTile(AIMap.GetTileIndex(t_x, t_y - 1)) == true) && (AIRoad.IsRoadTile(AIMap.GetTileIndex(t_x, t_y - 1)) == true) && (stationBuilt == false)) {
                AILog.Info("Neighbor Road is South")
                AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(t_x, t_y), AIMap.GetTileIndex(t_x, t_y - 1), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)
                stationBuilt = true
                break;
              }
            } else {
              AILog.Info("No Non-Junctions South")
            }
          }

          /* Try to Find Non-Junction East */
          for (i=10; i<15 && (stationBuilt == false); i++) {
          x_a = x_a + 1
          if (AIRoad.GetNeighbourRoadCount(AIMap.GetTileIndex(x_a, y_a)) < 3 && (stationBuilt == false)) {
              t_x = x_a
              t_y = y_a
              t_index = AIMap.GetTileIndex(t_x, t_y);
              AILog.Info("Found Non-Junction East of Town Center")
              /* See if Neighbor Road is East */
              if ((AIMap.IsValidTile(AIMap.GetTileIndex(t_x + 1, t_y)) == true) && (AIRoad.IsRoadTile(AIMap.GetTileIndex(t_x + 1, t_y)) == true) && (stationBuilt == false)) {
                AILog.Info("Neighbor Road is East")
                AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(t_x, t_y), AIMap.GetTileIndex(t_x + 1, t_y), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)
                stationBuilt = true
                break;
                /* See if Neighbor Road is West */
              } else if ((AIMap.IsValidTile(AIMap.GetTileIndex(t_x - 1, t_y)) == true) && (AIRoad.IsRoadTile(AIMap.GetTileIndex(t_x - 1, t_y)) == true) && (stationBuilt == false)) {
                AILog.Info("Neighbor Road is West")
                AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(t_x, t_y), AIMap.GetTileIndex(t_x - 1, t_y), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)
                stationBuilt = true
                break;
                /* See if Neighbor Road is North */
              } else if ((AIMap.IsValidTile(AIMap.GetTileIndex(t_x, t_y + 1)) == true) && (AIRoad.IsRoadTile(AIMap.GetTileIndex(t_x, t_y + 1)) == true) && (stationBuilt == false)) {
                AILog.Info("Neighbor Road is North")
                AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(t_x, t_y), AIMap.GetTileIndex(t_x, t_y + 1), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)
                stationBuilt = true
                break;
                /* See if Neighbor Road is South */
              } else if ((AIMap.IsValidTile(AIMap.GetTileIndex(t_x, t_y - 1)) == true) && (AIRoad.IsRoadTile(AIMap.GetTileIndex(t_x, t_y - 1)) == true) && (stationBuilt == false)) {
                AILog.Info("Neighbor Road is South")
                AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(t_x, t_y), AIMap.GetTileIndex(t_x, t_y - 1), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)
                stationBuilt = true
                break;
              }
            } else {
              AILog.Info("No Non-Junctions East")
            }
          }

          /* Try to Find Non-Junction West */
          for (i=15; i<20 && (stationBuilt == false); i++) {
          x_a = x_a - 1
          if (AIRoad.GetNeighbourRoadCount(AIMap.GetTileIndex(x_a, y_a)) < 3 && (stationBuilt == false)) {
              t_x = x_a
              t_y = y_a
              t_index = AIMap.GetTileIndex(t_x, t_y);
              AILog.Info("Found Non-Junction West of Town Center")
              /* See if Neighbor Road is East */
              if ((AIMap.IsValidTile(AIMap.GetTileIndex(t_x + 1, t_y)) == true) && (AIRoad.IsRoadTile(AIMap.GetTileIndex(t_x + 1, t_y)) == true) && (stationBuilt == false)) {
                AILog.Info("Neighbor Road is East")
                AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(t_x, t_y), AIMap.GetTileIndex(t_x + 1, t_y), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)
                stationBuilt = true
                break;
                /* See if Neighbor Road is West */
              } else if ((AIMap.IsValidTile(AIMap.GetTileIndex(t_x - 1, t_y)) == true) && (AIRoad.IsRoadTile(AIMap.GetTileIndex(t_x - 1, t_y)) == true) && (stationBuilt == false)) {
                AILog.Info("Neighbor Road is West")
                AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(t_x, t_y), AIMap.GetTileIndex(t_x - 1, t_y), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)
                stationBuilt = true
                break;
                /* See if Neighbor Road is North */
              } else if ((AIMap.IsValidTile(AIMap.GetTileIndex(t_x, t_y + 1)) == true) && (AIRoad.IsRoadTile(AIMap.GetTileIndex(t_x, t_y + 1)) == true) && (stationBuilt == false)) {
                AILog.Info("Neighbor Road is North")
                AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(t_x, t_y), AIMap.GetTileIndex(t_x, t_y + 1), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)
                stationBuilt = true
                break;
                /* See if Neighbor Road is South */
              } else if ((AIMap.IsValidTile(AIMap.GetTileIndex(t_x, t_y - 1)) == true) && (AIRoad.IsRoadTile(AIMap.GetTileIndex(t_x, t_y - 1)) == true) && (stationBuilt == false)) {
                AILog.Info("Neighbor Road is South")
                AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(t_x, t_y), AIMap.GetTileIndex(t_x, t_y - 1), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)
                stationBuilt = true
                break;
              }
            } else {
              AILog.Info("No Non-Junctions West")
            }
          }   
      }
      while (true) {
      AILog.Info("I am a very new AI with a ticker called AutonomousInstitutions and I am at tick " + this.GetTick());
      this.Sleep(50);
      }
    }
      /* Build Station in Town B */
        /* Set Coordinates for Town Center */
  }
}