//=============================================================================
// AmmoNanoVirusGrenade.
//=============================================================================
class AmmoNanoVirusGrenade extends DeusExAmmo;

defaultproperties
{
     VM_isGrenade=True
     AmmoAmount=1
     MaxAmmo=10
     PickupViewMesh=LodMesh'DeusExItems.TestBox'
     Icon=Texture'DeusExUI.Icons.BeltIconWeaponNanoVirus'
     beltDescription="SCRM GREN"
     Mesh=LodMesh'DeusExItems.TestBox'
     CollisionRadius=22.500000
     CollisionHeight=16.000000
     bCollideActors=True
}
