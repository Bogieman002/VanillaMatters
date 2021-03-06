//=============================================================================
// WeaponAssaultGun.
//=============================================================================
class WeaponAssaultGun extends DeusExWeapon;

// Vanilla Matters: Import custom fire sound to accomodate 3-round burst.
// Stupid Ex: Import these using 'ucc build'.
/*
#exec AUDIO IMPORT FILE="Sounds\AssaultGun\fire1.wav"		NAME="AssaultGunFire1"		GROUP="VMSounds"
#exec AUDIO IMPORT FILE="Sounds\AssaultGun\fire2.wav"		NAME="AssaultGunFire2"		GROUP="VMSounds"
#exec AUDIO IMPORT FILE="Sounds\AssaultGun\fire3.wav"		NAME="AssaultGunFire3"		GROUP="VMSounds"
#exec AUDIO IMPORT FILE="Sounds\AssaultGun\fire4.wav"		NAME="AssaultGunFire4"		GROUP="VMSounds"
#exec AUDIO IMPORT FILE="Sounds\AssaultGun\fire5.wav"		NAME="AssaultGunFire5"		GROUP="VMSounds"
*/

var float	mpRecoilStrength;

// Vanilla Matters
// Stupid Ex: Added in '()'
var() Sound VM_fireSounds[5];

simulated function PreBeginPlay()
{
	Super.PreBeginPlay();

	// If this is a netgame, then override defaults
	if ( Level.NetMode != NM_StandAlone )
	{
		HitDamage = mpHitDamage;
		BaseAccuracy = mpBaseAccuracy;
		ReloadTime = mpReloadTime;
		AccurateRange = mpAccurateRange;
		MaxRange = mpMaxRange;
		ReloadCount = mpReloadCount;

		// Tuned for advanced -> master skill system (Monte & Ricardo's number) client-side
		recoilStrength = 0.75;
	}
}

// Vanilla Matters: Randomize between all the firing sounds.
simulated function PlayFiringSound() {
	FireSound = VM_fireSounds[Rand( 4 )];

	super.PlayFiringSound();
}

defaultproperties
{
     VM_fireSounds(0)=Sound'DeusEx.Weapons.AssaultGunFire1'
     VM_fireSounds(1)=Sound'DeusEx.Weapons.AssaultGunFire2'
     VM_fireSounds(2)=Sound'DeusEx.Weapons.AssaultGunFire3'
     VM_fireSounds(3)=Sound'DeusEx.Weapons.AssaultGunFire4'
     VM_fireSounds(4)=Sound'DeusEx.Weapons.AssaultGunFire5'
     LowAmmoWaterMark=30
     GoverningSkill=Class'DeusEx.SkillWeaponPistol'
     EnviroEffective=ENVEFF_Air
     Concealability=CONC_Visual
     bAutomatic=True
     ShotTime=0.150000
     reloadTime=3.000000
     maxRange=3200
     AccurateRange=1600
     BaseAccuracy=0.700000
     bCanHaveLaser=True
     bCanHaveSilencer=True
     AmmoNames(0)=Class'DeusEx.Ammo762mm'
     AmmoNames(1)=Class'DeusEx.Ammo20mm'
     ProjectileNames(1)=Class'DeusEx.HECannister20mm'
     recoilStrength=0.500000
     MinWeaponAcc=0.200000
     mpReloadTime=0.500000
     mpHitDamage=10
     mpBaseAccuracy=1.000000
     mpAccurateRange=2400
     mpMaxRange=2400
     mpReloadCount=30
     bCanHaveModBaseAccuracy=True
     bCanHaveModReloadCount=True
     bCanHaveModAccurateRange=True
     bCanHaveModReloadTime=True
     bCanHaveModRecoilStrength=True
     VM_handsTexPos(0)=0
     VM_handsTexPos(1)=3
     AmmoName=Class'DeusEx.Ammo762mm'
     ReloadCount=30
     PickupAmmoCount=30
     bInstantHit=True
     FireOffset=(X=-16.000000,Y=5.000000,Z=11.500000)
     shakemag=150.000000
     FireSound=Sound'DeusEx.Weapons.AssaultGunFire1'
     AltFireSound=Sound'DeusExSounds.Weapons.AssaultGunReloadEnd'
     CockingSound=Sound'DeusExSounds.Weapons.AssaultGunReload'
     SelectSound=Sound'DeusExSounds.Weapons.AssaultGunSelect'
     InventoryGroup=4
     ItemName="Assault Rifle"
     ItemArticle="an"
     PlayerViewOffset=(X=16.000000,Y=-5.000000,Z=-11.500000)
     PlayerViewMesh=LodMesh'DeusExItems.AssaultGun'
     PickupViewMesh=LodMesh'DeusExItems.AssaultGunPickup'
     ThirdPersonMesh=LodMesh'DeusExItems.AssaultGun3rd'
     LandSound=Sound'DeusExSounds.Generic.DropMediumWeapon'
     Icon=Texture'DeusExUI.Icons.BeltIconAssaultGun'
     largeIcon=Texture'DeusExUI.Icons.LargeIconAssaultGun'
     largeIconWidth=94
     largeIconHeight=65
     invSlotsX=2
     invSlotsY=2
     Description="The 7.62x51mm assault rifle is designed for close-quarters combat, utilizing a shortened barrel and 'bullpup' design for increased maneuverability. An additional underhand 20mm HE launcher increases the rifle's effectiveness against a variety of targets."
     beltDescription="ASSAULT"
     Mesh=LodMesh'DeusExItems.AssaultGunPickup'
     CollisionRadius=15.000000
     CollisionHeight=1.100000
     Mass=30.000000
}
