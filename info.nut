class AutonomousInstitutions extends AIInfo {
  function GetAuthor()      { return "Autonomous Developments"; }
  function GetName()        { return "AutonomousInstitutions"; }
  function GetDescription() { return "An example AI by following the tutorial at http://wiki.openttd.org/"; }
  function GetVersion()     { return 1; }
  function GetDate()        { return "2014-05-30"; }
  function CreateInstance() { return "AutonomousInstitutions"; }
  function GetShortName()   { return "AUTO"; }
  function GetAPIVersion()  { return "1.0"; }
}

/* Tell the core we are an AI */
RegisterAI(AutonomousInstitutions());