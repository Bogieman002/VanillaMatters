//=============================================================================
// SkillEnviro.
//=============================================================================
class SkillEnviro extends Skill;

var int mpCost1;
var int mpCost2;
var int mpCost3;
var float mpLevel0;
var float mpLevel1;
var float mpLevel2;
var float mpLevel3;

simulated function PreBeginPlay()
{
	Super.PreBeginPlay();

	if ( Level.NetMode != NM_Standalone )
	{
		cost[0] = mpCost1;
		cost[1] = mpCost2;
		cost[2] = mpCost3;
		LevelValues[0] = mpLevel0;
		LevelValues[1] = mpLevel1;
		LevelValues[2] = mpLevel2;
		LevelValues[3] = mpLevel3;
	}
}

defaultproperties
{
     mpCost1=1000
     mpCost2=1000
     mpCost3=1000
     mpLevel0=1.000000
     mpLevel1=0.750000
     mpLevel2=0.500000
     mpLevel3=0.250000
     SkillName="Environmental Training"
     Description="Experience with operating in various hazardous environments, and using specialized equipments.|n|nUNTRAINED: An agent can use hazmat suits, ballistic armor, thermoptic camo, rebreathers and tech goggles. An agent can also swim normally.|n|nTRAINED:|n+33% suits' durability.|n+50% swimming speed and lung capacity.|n+25% damage resistance from ballistic armor and hazmat suit (diminishingly).|n- Tech Goggles have infravision.|n|nADVANCED:|n+100% suits' durability.|n+100% swimming speed and lung capacity.|n+50% damage resistance from ballistic armor and hazmat suit (diminishingly).|n- Tech Goggles have close range sonar imaging.|n|nMASTER: An agent wears suits and armor like a second skin, moves like a dolphin underwater.|n+300% suits' durability.|n+150% swimming speed and lung capacity.|n+75% damage resistance from ballistic armor and hazmat suit (diminishingly).|n+100% Tech Goggles sonar range."
     SkillIcon=Texture'DeusExUI.UserInterface.SkillIconEnviro'
     bAutomatic=True
     cost(0)=900
     cost(1)=1800
     cost(2)=3000
     LevelValues(0)=1.000000
     LevelValues(1)=0.750000
     LevelValues(2)=0.500000
     LevelValues(3)=0.250000
     VM_SwimmingLevelValues(0)=1.000000
     VM_SwimmingLevelValues(1)=1.500000
     VM_SwimmingLevelValues(2)=2.000000
     VM_SwimmingLevelValues(3)=2.500000
}