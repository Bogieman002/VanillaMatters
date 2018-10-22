//=============================================================================
// AugVision.
//=============================================================================
class AugVision extends Augmentation;

var float mpAugValue;
var float mpEnergyDrain;

// ----------------------------------------------------------------------------
// Networking Replication
// ----------------------------------------------------------------------------

replication
{
   //server to client function calls
   reliable if (Role == ROLE_Authority)
      SetVisionAugStatus;
}

// Vanilla Matters: I don't even know what the heck is going on here so I'm gonna rewrite this mess.
state Active {
	function BeginState() {
		SetVisionAugStatus( CurrentLevel + 1, LevelValues[CurrentLevel], true );
		Player.RelevantRadius = LevelValues[CurrentLevel];
	}
Begin:
}

state Inactive {
	function BeginState() {
		SetVisionAugStatus( 0, 0, false );
		Player.RelevantRadius = 0;
	}
Begin:
}

// ----------------------------------------------------------------------
// SetVisionAugStatus()
// ----------------------------------------------------------------------

// Vanilla Matters: Gonna rewrite the mess above for readability.
simulated function SetVisionAugStatus( int Level, float LevelValue, bool active ) {
	local AugmentationDisplayWindow augWnd;

	augWnd = DeusExRootWindow( Player.rootWindow ).hud.augDisplay;

	if ( active ) {
		augWnd.VM_visionLevels[1] = Level;
		augWnd.VM_visionValues[1] = LevelValue;
	}
	else {
		augWnd.visionBlinder = none;

		augWnd.VM_visionLevels[1] = 0;
		augWnd.VM_visionValues[1] = 0;
	}
}

simulated function PreBeginPlay()
{
	Super.PreBeginPlay();

	// If this is a netgame, then override defaults
	if ( Level.NetMode != NM_StandAlone )
	{
		LevelValues[3] = mpAugValue;
		EnergyRate = mpEnergyDrain;
	}
}

defaultproperties
{
     mpAugValue=1000.000000
     mpEnergyDrain=60.000000
     EnergyRate=6.000000
     Icon=Texture'DeusExUI.UserInterface.AugIconVision'
     smallIcon=Texture'DeusExUI.UserInterface.AugIconVision_Small'
     AugmentationName="Vision Enhancement"
     Description="By bleaching selected rod photoreceptors and saturating them with metarhodopsin XII, the 'nightvision' present in most nocturnal animals can be duplicated. Subsequent upgrades and modifications add infravision and sonar-resonance imaging that effectively allows an agent to see through walls.|n|nTECH ONE: Nightvision.|n|nTECH TWO: Infravision.|n|nTECH THREE: Medium range sonar imaging.|n|nTECH FOUR: Long range sonar imaging."
     MPInfo="When active, you can see enemy players in the dark from any distance, and for short distances you can see through walls and see cloaked enemies.  Energy Drain: Moderate"
     LevelValues(2)=800.000000
     LevelValues(3)=1600.000000
     AugmentationLocation=LOC_Eye
     MPConflictSlot=6
     VM_EnergyRateAddition(1)=12.000000
     VM_EnergyRateAddition(2)=18.000000
     VM_EnergyRateAddition(3)=24.000000
     VM_dragIcon=Texture'DeusEx.Icons.AugIconVision'
}
