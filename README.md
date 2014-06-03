OpenTTD_AutoAI
==============

###Overview:
Autonomous Institutions (AutoAI) is an indevelopment Artificial Intelligence for OpenTTD written in Squirrel. 

###Features:
  * Name Selection
    - ensures company names do not overlap
    - defaults to AutonomousInstitutions
  * City Selection
    - selects the most populous city (townid_a)
    - selects the city closest to townid_a
  * Road Pathfinding
    - finds path between cities
    - builds connecting road
  * Depot Construction
    - finds townid_a center
    - checks in every direction 5 blocks for buildable tile
    - checks buildable tiles for adjacent road tile
    - builds road depot

###Planned:
  * v 0.2
    - Station Construction
    - Vehicle Purchase
    - Order Scheduling
