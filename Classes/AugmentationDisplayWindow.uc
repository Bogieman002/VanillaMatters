//=============================================================================
// AugmentationDisplayWindow.
//=============================================================================
class AugmentationDisplayWindow extends HUDBaseWindow;

var ViewportWindow winZoom;
var float margin;
var float corner;

var bool bDefenseActive;
var int defenseLevel;

var ViewportWindow winDrone;
var bool bDroneCreated;
var bool bDroneReferenced;
//var SpyDrone aDrone;		// MBCODE: Took this out and moved it to DeusExPlayer since the server
									// has no idea about these windows or the drone (needed for multiplayer).

var bool bTargetActive;
var int targetLevel;
var Actor lastTarget;
var float lastTargetTime;

var bool bVisionActive;
var int visionLevel;
var float visionLevelValue;

var localized String msgRange;
var localized String msgRangeUnits;
var localized String msgHigh;
var localized String msgMedium;
var localized String msgLow;
var localized String msgHealth;
var localized String msgOverall;
var localized String msgPercent;
var localized String msgHead;
var localized String msgTorso;
var localized String msgLeftArm;
var localized String msgRightArm;
var localized String msgLeftLeg;
var localized String msgRightLeg;
var localized String msgLegs;
var localized String msgWeapon;
var localized String msgNone;
var localized String msgScanning1;
var localized String msgScanning2;
var localized String msgADSTracking;
var localized String msgADSDetonating;
var localized String msgBehind;
var localized String msgDroneActive;
var localized String msgEnergyLow;
var localized String msgCantLaunch;
var localized String msgLightAmpActive;
var localized String msgIRAmpActive;
var localized String msgNoImage;
var localized String msgDisabled;
var localized String SpottedTeamString;
var localized String YouArePoisonedString;
var localized String YouAreBurnedString;
var localized String TurretInvincibleString;
var localized String CameraInvincibleString;
var localized String NeutBurnPoisonString;
var localized String	OnlyString;
var localized String KillsToGoString;
var localized String KillToGoString;
var localized String	LessThanMinuteString;
var localized String	LessThanXString1;
var localized String	LessThanXString2;
var localized String	LeadsMatchString;
var localized String	TiedMatchString;
var localized String WillWinMatchString;
var localized String OutOfRangeString;
var localized String LostLegsString;
var localized String DropItem1String;
var localized String DropItem2String;
var localized String msgTeammateHit, msgTeamNsf, msgTeamUnatco;
var localized String	UseString;
var localized String	TeamTalkString;
var localized String	TalkString;
var localized String YouKilledTeammateString;
var localized String TeamLAMString;
var localized String TeamComputerString;
var localized String NoCloakWeaponString;
var localized String TeamHackTurretString;
var localized String KeyNotBoundString;

var localized String OutOfAmmoString;
var float OutOfAmmoTime;

var Actor VisionBlinder; //So the same thing doesn't blind me twice.

var int VisionTargetStatus; //For picking see through wall texture
const VISIONENEMY = 1;
const VISIONALLY = 2;
const VISIONNEUTRAL = 0;

// Show name of player in multiplayer on a timer
var String	targetPlayerName;					// Player's name in targeting reticle
var String  targetPlayerHealthString;     // Target player's health (for targeting aug)'
var String  targetPlayerLocationString;   // Point on target player at which you are aiming (For multiplayer)
var float	targetPlayerTime;					// Timer
var float	targetRangeTime;
var color	targetPlayerColor;				// Color red or green
var bool		targetOutOfRange;					// Is target out of range with current weapon
const			targetPlayerDelay		= 3;			// Delay in seconds until name is not displayed
const			targetPlayerXMul		= 0.08;
const			targetPlayerYMul		= 0.79;

var String	keyDropItem, keyTalk, keyTeamTalk;

var Color	colRed, colGreen, colWhite;

// Vanilla Matters
var Actor defenseTarget;				// AugDefense now deals with more than projectiles.
var bool VM_bDefenseEnoughEnergy;		// AugDefense now has a cost so the HUD has to deal with whether a detonation is possible.
var bool VM_bDefenseEnoughDistance;		// Shows if we're in range to detonate.

var ViewportWindow VM_playerWnd;		// Holds the player perspective when AugDrone is on.

var bool VM_recticleDrawn;				// True if we're drawing the weapon recticle.

var int VM_visionLevels[2];				// Use an array to hold seperate values from different sources of vision.
var int VM_visionValues[2];

var() float VM_nvBrightness;
var() float VM_irBrightness;

var localized String VM_msgUndefined;
var localized String VM_msgADSNotEnoughEnergy;

// ----------------------------------------------------------------------
// InitWindow()
// ----------------------------------------------------------------------

event InitWindow()
{
	Super.InitWindow();
	bTickEnabled = True;
	Lower();
	RefreshMultiplayerKeys();
}

// ----------------------------------------------------------------------
// TraceLOS()
// ----------------------------------------------------------------------

function Actor TraceLOS(float checkDist, out vector HitLocation)
{
	local Actor target;
	local Vector HitLoc, HitNormal, StartTrace, EndTrace;

	target = None;

	// figure out how far ahead we should trace
	StartTrace = Player.Location;
	EndTrace = Player.Location + (Vector(Player.ViewRotation) * checkDist);

	// adjust for the eye height
	StartTrace.Z += Player.BaseEyeHeight;
	EndTrace.Z += Player.BaseEyeHeight;

	// find the object that we are looking at
	// make sure we don't select the object that we're carrying
	foreach Player.TraceActors(class'Actor', target, HitLoc, HitNormal, EndTrace, StartTrace)
	{
		if (target.IsA('Pawn') || target.IsA('DeusExDecoration') || target.IsA('ThrownProjectile') ||
			(target.IsA('DeusExMover') && DeusExMover(target).bBreakable))
		{
			if (target != Player.CarriedDecoration)
			{
				if ( (Player.Level.NetMode != NM_Standalone) && target.IsA('DeusExPlayer') )
				{
					if ( DeusExPlayer(target).AdjustHitLocation( HitLoc, EndTrace - StartTrace ) )
						break;
					else
						target = None;
				}
				else
					break;
			}
		}
	}

	HitLocation = HitLoc;

	return target;
}

// ----------------------------------------------------------------------
// Interpolate()
// ----------------------------------------------------------------------

function Interpolate(GC gc, float fromX, float fromY, float toX, float toY, int power)
{
	local float xPos, yPos;
	local float deltaX, deltaY;
	local float maxDist;
	local int   points;
	local int   i;

	maxDist = 16;

	points = 1;
	deltaX = (toX-fromX);
	deltaY = (toY-fromY);
	while (power >= 0)
	{
		if ((deltaX >= maxDist) || (deltaX <= -maxDist) || (deltaY >= maxDist) || (deltaY <= -maxDist))
		{
			deltaX *= 0.5;
			deltaY *= 0.5;
			points *= 2;
			power--;
		}
		else
			break;
	}

	xPos = fromX + ((Player.Level.TimeSeconds % 0.5) * deltaX * 2);
	yPos = fromY + ((Player.Level.TimeSeconds % 0.5) * deltaY * 2);
	for (i=0; i<points-1; i++)
	{
		xPos += deltaX;
		yPos += deltaY;
		gc.DrawPattern(xPos, yPos, 2, 2, 0, 0, Texture'Solid');
	}
}

// ----------------------------------------------------------------------
// ConfigurationChanged()
// ----------------------------------------------------------------------

function ConfigurationChanged()
{
	local float x, y, w, h, cx, cy;

	// Vanilla Matters: Tweak the locations of the windows.
	if ( winDrone != none ) {
		winDrone.ConfigureChild( 0, 0, width, height );
	}

	x = margin;
	y = height * 0.375;
	w = width / 4;
	h = height / 4;
	
	if ( VM_playerWnd != none ) {
		VM_playerWnd.ConfigureChild( x, y, w, h );
	}

	x = width - ( width / 4 ) - margin;

	if ( winZoom != none ) {
		winZoom.ConfigureChild( x, y, w, h );
	}
}

// ----------------------------------------------------------------------
// ChildRequestedReconfiguration()
// ----------------------------------------------------------------------

function bool ChildRequestedReconfiguration(Window childWin)
{
	ConfigurationChanged();

	return True;
}

// ----------------------------------------------------------------------
// RefreshMultiplayerKeys()
// ----------------------------------------------------------------------
function RefreshMultiplayerKeys()
{
	local String Alias, keyName;
	local int i;

	for ( i = 0; i < 255; i++ )
	{
		keyName = player.ConsoleCommand ( "KEYNAME "$i );
		if ( keyName != "" )
		{
			Alias = player.ConsoleCommand( "KEYBINDING "$keyName );
			if ( Alias ~= "DropItem" )
				keyDropItem = keyName;
			else if ( Alias ~= "Talk" )
				keyTalk = keyName;
			else if ( Alias ~= "TeamTalk" )
				keyTeamTalk = keyName;
		}
	}
	if ( keyDropItem ~= "" )
		keyDropItem = KeyNotBoundString;
	if ( keyTalk ~= "" )
		keyTalk = KeyNotBoundString;
	if ( keyTeamTalk ~= "" )
		keyTeamTalk = KeyNotBoundString;
}


// ----------------------------------------------------------------------
// Tick()
// ----------------------------------------------------------------------

function Tick(float deltaTime)
{
	// check for the drone ViewportWindow being constructed

	// Vanilla Matters: When AugDrone is active, make the spy drone's perspective the main one and shift the player's down to a smaller window.
	if ( player.bSpyDroneActive && player.aDrone != none && ( player.PlayerIsClient() || player.Level.NetMode == NM_Standalone ) ) {
		if ( VM_playerWnd == none ) {
			VM_playerWnd = ViewportWindow( NewChild( class'ViewportWindow' ) );
			VM_playerWnd.AskParentForReconfigure();
			VM_playerWnd.Lower();
			VM_playerWnd.SetViewportActor( player );
		}
		if ( winDrone == none ) {
			winDrone = ViewportWindow( NewChild( class'ViewportWindow' ) );
			winDrone.AskParentForReconfigure();
			winDrone.Lower();
			winDrone.SetViewportActor( player.aDrone );
		}
	}

	if ( !player.bSpyDroneActive ) {
		if ( winDrone != none ) {
			winDrone.Destroy();
			winDrone = none;
		}
		if ( VM_playerWnd != none ) {
			VM_playerWnd.Destroy();
			VM_playerWnd = none;
		}

		if ( player.aDrone != none && IsActorValid( player.aDrone ) ) {
			RemoveActorRef( player.aDrone );
			bDroneReferenced = false;
		}

		bDroneCreated = false;
	}

	// check for the target ViewportWindow being constructed
	if (bTargetActive && (targetLevel > 2) && (winZoom == None) && (lastTarget != None) && (Player.Level.NetMode == NM_Standalone))
	{
		winZoom = ViewportWindow(NewChild(class'ViewportWindow'));
		if (winZoom != None)
		{
			winZoom.AskParentForReconfigure();
			winZoom.Lower();
		}
	}

	if (winZoom != None)
	{
		if ((bTargetActive && (lastTarget == None)) || !bTargetActive)
		{
			winZoom.Destroy();
			winZoom = None;
		}
	}
}

// ----------------------------------------------------------------------
// PostDrawWindow()
// ----------------------------------------------------------------------

function PostDrawWindow(GC gc)
{
	local PlayerPawn pp;

	pp = Player.GetPlayerPawn();

   //DEUS_EX AMSD Draw vision first so that everything else doesn't get washed green

	// Vanilla Matters: Handle active status in the function itself.
	DrawVisionAugmentation( gc );

	if ( Player.Level.NetMode != NM_Standalone )
		DrawMiscStatusMessages( gc );

	if (bDefenseActive)
		DrawDefenseAugmentation(gc);

	if (Player.bSpyDroneActive)
		DrawSpyDroneAugmentation(gc);

   // draw IFF and accuracy information all the time, return False if target aug is not active
	DrawTargetAugmentation(gc);

	gc.SetFont(Font'FontMenuSmall_DS');
	gc.SetTextColor(colHeaderText);
	gc.SetStyle(DSTY_Normal);
	gc.SetTileColor(colBorder);

   if ( (pp != None) && (pp.bShowScores) )
	{
		if ( DeathMatchGame(Player.DXGame) != None )
			DeathMatchGame(Player.DXGame).ShowDMScoreboard( Player, gc, width, height );
		else if ( TeamDMGame(Player.DXGame) != None )
			TeamDMGame(Player.DXGame).ShowTeamDMScoreboard( Player, gc, width, height );
	}
}

// ----------------------------------------------------------------------
// DrawDefenseAugmentation()
// ----------------------------------------------------------------------

function DrawDefenseAugmentation(GC gc)
{
	local String str;
	local float boxCX, boxCY;
	local float x, y, w, h, mult;
	local bool bDrawLine;

	// Vanilla Matters
	// local DeusExWeapon targetWeapon;
	// local ScriptedPawn sp;
	// local Vector vX, vY, vZ;
	local Vector targetLocation;

	if (defenseTarget != None)
	{
		bDrawLine = False;

		// Vanilla Matters: Rewrite all the stuff to take into account new target types.
		bDrawLine = true;

		if ( VM_bDefenseEnoughDistance ) {
			str = msgADSDetonating;
		}
		else {
			str = msgADSTracking;
		}

		// sp = ScriptedPawn( defenseTarget );

		// if ( sp != None ) {
		// 	targetWeapon = DeusExWeapon( sp.Weapon );

		// 	if ( targetWeapon != None ) {
		// 		targetLocation = defenseTarget.Location - ( ( sp.default.CollisionHeight - sp.CollisionHeight ) * 0.5 * vect( 0, 0, 1 ) ) + ( targetWeapon.FireOffset >> sp.ViewRotation );
		// 	}
		// 	else {
		// 		targetLocation = defenseTarget.Location;
		// 	}
		// }
		// else {
		// 	targetLocation = defenseTarget.Location;
		// }

		targetLocation = defenseTarget.Location;

		// VM: If the player has enough energy to detonation, display range, otherwise, say so.
		if ( VM_bDefenseEnoughEnergy ) {
			str = str $ CR() $ msgRange @ Int( VSize( targetLocation - Player.Location ) / 16 ) @ msgRangeUnits;

			if ( !ConvertVectorToCoordinates( targetLocation, boxCX, boxCY ) ) {
				str = str @ msgBehind;
			}
		}
		else {
			str = VM_msgADSNotEnoughEnergy;
		}

		gc.GetTextExtent( 0, w, h, str );
		x = boxCX - w / 2;
		y = boxCY - h - 11;
		gc.SetTextColorRGB( 255, 0, 0 );
		gc.DrawText( x, y, w, h, str );
		gc.SetTextColor( colHeaderText );

		if (bDrawLine) {
			gc.SetTileColorRGB( 255, 0, 0 );
			Interpolate( gc, width / 2, height / 2, boxCX, boxCY, 64 );
			gc.SetTileColor( colHeaderText );

			// VM: Draw four corners of the box.
			// gc.DrawPattern( boxCX - 10, boxCY - 10, 4, 1, 0, 0, Texture'SolidRed' );
			// gc.DrawPattern( boxCX - 10, boxCY - 10, 1, 4, 0, 0, Texture'SolidRed' );

			// gc.DrawPattern( boxCX + 5, boxCY - 10, 4, 1, 0, 0, Texture'SolidRed' );
			// gc.DrawPattern( boxCX + 10, boxCY - 10, 1, 4, 0, 0, Texture'SolidRed' );

			// gc.DrawPattern( boxCX - 10, boxCY + 10, 4, 1, 0, 0, Texture'SolidRed' );
			// gc.DrawPattern( boxCX - 10, boxCY + 5, 1, 4, 0, 0, Texture'SolidRed' );

			// gc.DrawPattern( boxCX + 5, boxCY + 10, 4, 1, 0, 0, Texture'SolidRed' );
			// gc.DrawPattern( boxCX + 10, boxCY + 5, 1, 4, 0, 0, Texture'SolidRed' );
		}
	}
}

// ----------------------------------------------------------------------
// DrawSpyDroneAugmentation()
// ----------------------------------------------------------------------

function DrawSpyDroneAugmentation(GC gc)
{
	local String str;
	local float boxCX, boxCY, boxTLX, boxTLY, boxBRX, boxBRY, boxW, boxH;
	local float x, y, w, h, mult;
	local Vector loc;

	// set the coords of the drone window
	boxW = width/4;
	boxH = height/4;
	boxCX = width/8 + margin;
	boxCY = height/2;
	boxTLX = boxCX - boxW/2;
	boxTLY = boxCY - boxH/2;
	boxBRX = boxCX + boxW/2;
	boxBRY = boxCY + boxH/2;

	if (winDrone != None)
	{
		DrawDropShadowBox(gc, boxTLX, boxTLY, boxW, boxH);

		str = msgDroneActive;
		gc.GetTextExtent(0, w, h, str);
		x = boxCX - w/2;
		y = boxTLY - h - margin;
		gc.DrawText(x, y, w, h, str);

		// print a low energy warning message
		if ((Player.Energy / Player.Default.Energy) < 0.2)
		{
			str = msgEnergyLow;
			gc.GetTextExtent(0, w, h, str);
			x = boxCX - w/2;
			y = boxTLY + margin;
			gc.SetTextColorRGB(255,0,0);
			gc.DrawText(x, y, w, h, str);
			gc.SetTextColor(colHeaderText);
		}
	}
	// Since drone is created on server, they is a delay in when it will actually show up on the client
	// the flags dronecreated and drone referenced negotiate this timing
	if ( !bDroneCreated )  	
	{
		if (Player.aDrone == None)
		{
			bDroneCreated = true;
			Player.CreateDrone();
		}
	}
	else if ( !bDroneReferenced )
	{
		if ( Player.aDrone != None )
		{
			bDroneReferenced = true;
			AddActorRef( Player.aDrone );
		}
	}
}

//-------------------------------------------------------------------------------------------------
// TopCentralMessage()
//-------------------------------------------------------------------------------------------------

function float TopCentralMessage( GC gc, String str, color textColor )
{
	local float x, y, w, h;

	gc.SetFont(Font'FontMenuTitle');
	gc.GetTextExtent( 0, w, h, str );
	gc.SetTextColor( textColor );
	x = (width * 0.5) - (w * 0.5);
	y = height * 0.33;
	DrawFadedText( gc, x, y, textColor, str );
	return( y + h );
}

// ----------------------------------------------------------------------
// DrawFadedText()
// ----------------------------------------------------------------------
function DrawFadedText( GC gc, float x, float y, Color msgColor, String msg )
{
	local Color adj;
	local float mul, w, h;

	EnableTranslucentText(True);
	gc.SetStyle(DSTY_Translucent);
	mul = FClamp( (Player.mpMsgTime - Player.Level.Timeseconds)/Player.mpMsgDelay, 0.0, 1.0 );
	adj.r = mul * msgColor.r;
	adj.g = mul * msgColor.g;
	adj.b = mul * msgColor.b;
	gc.SetTextColor(adj);
	gc.GetTextExtent( 0, w, h, msg );
	gc.DrawText( x, y, w, h, msg );
	gc.SetStyle(DSTY_Normal);
	EnableTranslucentText(False);
}

// ----------------------------------------------------------------------
// DrawMiscStatusMessages()
// ----------------------------------------------------------------------
function DrawMiscStatusMessages( GC gc )
{
	local DeusExWeapon weap;
	local float x, y, w, h, cury;
	local Color msgColor;
	local String str;
	local bool bNeutralMsg;
	local String dropKeyName, keyName;
	local int i;

	bNeutralMsg = False;

	if (( Player.Level.Timeseconds < Player.mpMsgTime ) && !Player.bShowScores )
	{
		msgColor = colGreen;

		switch( Player.mpMsgCode )
		{
			case Player.MPMSG_TeamUnatco:
				str = msgTeamUnatco;
				cury = TopCentralMessage( gc, str, msgColor );
				if ( keyTalk ~= KeyNotBoundString )
					RefreshMultiplayerKeys();
				str = UseString $ keyTalk $ TalkString;
				gc.GetTextExtent( 0, w, h, str );
				cury += h;
				DrawFadedText( gc, (width * 0.5) - (w * 0.5), cury, msgColor, str );
				if ( TeamDMGame(Player.DXGame) != None )
				{
					cury += h;
					if ( keyTeamTalk ~= KeyNotBoundString )
						RefreshMultiplayerKeys();
					str = UseString $ keyTeamTalk $ TeamTalkString;
					gc.GetTextExtent( 0, w, h, str );
					DrawFadedText( gc, (width * 0.5) - (w * 0.5), cury, msgColor, str );
				}
				break;
			case Player.MPMSG_TeamNsf:
				str = msgTeamNsf;
				cury = TopCentralMessage( gc, str, msgColor );
				if ( keyTalk ~= KeyNotBoundString )
					RefreshMultiplayerKeys();
				str = UseString $ keyTalk $ TalkString;
				gc.GetTextExtent( 0, w, h, str );
				cury += h;
				DrawFadedText( gc, (width * 0.5) - (w * 0.5), cury, msgColor, str );
				if ( TeamDMGame(Player.DXGame) != None )
				{
					cury += h;
					if ( keyTeamTalk ~= KeyNotBoundString )
						RefreshMultiplayerKeys();
					str = UseString $ keyTeamTalk $ TeamTalkString;
					gc.GetTextExtent( 0, w, h, str );
					DrawFadedText( gc, (width * 0.5) - (w * 0.5), cury, msgColor, str );
				}
				break;
			case Player.MPMSG_TeamHit:
				msgColor = colRed;
				str = msgTeammateHit;
				TopCentralMessage( gc, str, msgColor );
				break;
			case Player.MPMSG_TeamSpot:
				str = SpottedTeamString;
				TopCentralMessage( gc, str, msgColor );
				break;
			case Player.MPMSG_FirstPoison:
				str = YouArePoisonedString;
				cury = TopCentralMessage( gc, str, msgColor );
				gc.GetTextExtent( 0, w, h, NeutBurnPoisonString );
				x = (width * 0.5) - (w * 0.5);
				DrawFadedText( gc, x, cury, msgColor, NeutBurnPoisonString );
				break;
			case Player.MPMSG_FirstBurn:
				str = YouAreBurnedString;
				cury = TopCentralMessage( gc, str, msgColor );
				gc.GetTextExtent( 0, w, h, NeutBurnPoisonString );
				x = (width * 0.5) - (w * 0.5);
				DrawFadedText( gc, x, cury, msgColor, NeutBurnPoisonString );
				break;
			case Player.MPMSG_TurretInv:
				str = TurretInvincibleString;
				TopCentralMessage( gc, str, msgColor );
				break;
			case Player.MPMSG_CameraInv:
				str = CameraInvincibleString;
				TopCentralMessage( gc, str, msgColor );
				break;
			case Player.MPMSG_CloseKills:
				if ( Player.mpMsgOptionalParam > 1 )
					str = OnlyString $ Player.mpMsgOptionalParam $ KillsToGoString;
				else
					str = OnlyString $ Player.mpMsgOptionalParam $ KillToGoString;
				if ( Player.mpMsgOptionalString ~= "Tied" )	// Should only happen in a team game
					str = str $ TiedMatchString;
				else
					str = str $ Player.mpMsgOptionalString $ WillWinMatchString;
				TopCentralMessage( gc, str, msgColor );
				break;
			case Player.MPMSG_TimeNearEnd:
				if ( Player.mpMsgOptionalParam > 1 )
					str = LessThanXString1 $ Player.mpMsgOptionalParam $ LessThanXString2;
				else
					str = LessThanMinuteString;

				if ( Player.mpMsgOptionalString ~= "Tied" )	// Should only happen in a team game
					str = str $ TiedMatchString;
				else
					str = str $ Player.mpMsgOptionalString $ LeadsMatchString;
				TopCentralMessage( gc, str, msgColor );
				break;
			case Player.MPMSG_LostLegs:
				str = LostLegsString;
				TopCentralMessage( gc, str, msgColor );
				break;
			case Player.MPMSG_DropItem:
				if ( keyDropItem ~= KeyNotBoundString )
					RefreshMultiplayerKeys();
				str = DropItem1String $ keyDropItem $ DropItem2String;
				TopCentralMessage( gc, str, msgColor );
				break;
			case Player.MPMSG_KilledTeammate:
				msgColor = colRed;
				TopCentralMessage( gc, YouKilledTeammateString, msgColor );
				break;
			case Player.MPMSG_TeamLAM:
				str = TeamLAMString;
				TopCentralMessage( gc, str, msgColor );
				break;
			case Player.MPMSG_TeamComputer:
				str = TeamComputerString;
				TopCentralMessage( gc, str, msgColor );
				break;
			case Player.MPMSG_NoCloakWeapon:
				str = NoCloakWeaponString;
				TopCentralMessage( gc, str, msgColor );
				break;
			case Player.MPMSG_TeamHackTurret:
				str = TeamHackTurretString;
				TopCentralMessage( gc, str, msgColor );
				break;
		}
		gc.SetTextColor(colWhite);
	}
	if ( Player.Level.Timeseconds < targetPlayerTime )
	{
		gc.SetFont(Font'FontMenuSmall');
		gc.GetTextExtent(0, w, h, targetPlayerName $ targetPlayerHealthString $ targetPlayerLocationString);
		gc.SetTextColor(targetPlayerColor);
		x = width * targetPlayerXMul - (w*0.5);
		if ( x < 1) x = 1;
		y = height * targetPlayerYMul;
		gc.DrawText( x, y, w, h, targetPlayerName $ targetPlayerHealthString $ targetPlayerLocationString);
		if (( targetOutOfRange ) && ( targetRangeTime > Player.Level.Timeseconds ))
		{
			gc.GetTextExtent(0, w, h, OutOfRangeString);
			x = (width * 0.5) - (w*0.5);
			y = (height * 0.5) - (h * 3.0);
			gc.DrawText( x, y, w, h, OutOfRangeString );
		}
		gc.SetTextColor(colWhite);
	}
	weap = DeusExWeapon(Player.inHand);
	if (( weap != None ) && ( weap.AmmoLeftInClip() == 0 ) && (weap.NumClips() == 0) )
	{
		// Vanilla Matters: We now have a grenade flag.
		if ( !weap.VM_isGrenade ) {
			if ( Player.Level.Timeseconds < OutOfAmmoTime )
			{
				gc.SetFont(Font'FontMenuTitle');
				gc.GetTextExtent( 0, w, h, OutOfAmmoString );
				gc.SetTextColor(colRed);
				x = (width*0.5) - (w*0.5);
				y = (height*0.5) - (h*5.0);
				gc.DrawText( x, y, w, h, OutOfAmmoString );
			}
			if ( Player.Level.Timeseconds-OutOfAmmoTime > 0.33 )
				OutOfAmmoTime = Player.Level.Timeseconds + 1.0;
		}
	}
}

// ----------------------------------------------------------------------
// GetTargetReticle()
// ----------------------------------------------------------------------

function GetTargetReticleColor( Actor target, out Color xcolor )
{
	local DeusExPlayer safePlayer;
	local AutoTurret turret;
	local bool bDM, bTeamDM;
	local Vector dist;
   local float SightDist;
	local DeusExWeapon w;
	local int team;
	local String titleString;

	// Vanilla Matters: Make it white if target is none.
	if ( target == none ) {
		xcolor = colWhite;

		return;
	}

	bDM = (DeathMatchGame(player.DXGame) != None);
	bTeamDM = (TeamDMGame(player.DXGame) != None);

	if ( target.IsA('ScriptedPawn') )
	{
		if (ScriptedPawn(target).GetPawnAllianceType(Player) == ALLIANCE_Hostile)
			xcolor = colRed;
		else
			xcolor = colGreen;
	}
	else if ( Player.Level.NetMode != NM_Standalone )	// Only do the rest in multiplayer
	{
		if ( target.IsA('DeusExPlayer') && (target != player) )	// Other players IFF
		{
			if ( bTeamDM && (TeamDMGame(player.DXGame).ArePlayersAllied(DeusExPlayer(target),player)) )
			{ 
				xcolor = colGreen;
				if ( (Player.mpMsgFlags & Player.MPFLAG_FirstSpot) != Player.MPFLAG_FirstSpot )
					Player.MultiplayerNotifyMsg( Player.MPMSG_TeamSpot );
			}
			else
				xcolor = colRed;

         SightDist = VSize(target.Location - Player.Location);

			if ( ( bTeamDM && (TeamDMGame(player.DXGame).ArePlayersAllied(DeusExPlayer(target),player))) ||
				  (target.Style != STY_Translucent) || (bVisionActive && (Sightdist <= VisionLevelValue)) )              
			{
				targetPlayerName = DeusExPlayer(target).PlayerReplicationInfo.PlayerName;
            // DEUS_EX AMSD Show health of enemies with the target active.
            if (bTargetActive)
               TargetPlayerHealthString = "(" $ int(100 * (DeusExPlayer(target).Health / Float(DeusExPlayer(target).Default.Health))) $ "%)";
				targetOutOfRange = False;
				w = DeusExWeapon(player.Weapon);
				if (( w != None ) && ( xcolor != colGreen ))
				{
					dist = player.Location - target.Location;
					if ( VSize(dist) > w.maxRange ) 
					{
						if (!(( WeaponAssaultGun(w) != None ) && ( Ammo20mm(WeaponAssaultGun(w).AmmoType) != None )))
						{
							targetRangeTime = Player.Level.Timeseconds + 0.1;
							targetOutOfRange = True;
						}
					}
				}
				targetPlayerTime = Player.Level.Timeseconds + targetPlayerDelay;
				targetPlayerColor = xcolor;
			}
			else
				xcolor = colWhite;	// cloaked enemy
		}
		else if (target.IsA('ThrownProjectile'))	// Grenades IFF
		{
			if ( ThrownProjectile(target).bDisabled )
				xcolor = colWhite;
			else if ( (bTeamDM && (ThrownProjectile(target).team == player.PlayerReplicationInfo.team)) || 
				(player == DeusExPlayer(target.Owner)) )
				xcolor = colGreen;
			else
				xcolor = colRed;
		}
		else if ( target.IsA('AutoTurret') || target.IsA('AutoTurretGun') ) // Autoturrets IFF
		{
			if ( target.IsA('AutoTurretGun') )
			{
				team = AutoTurretGun(target).team;
				titleString = AutoTurretGun(target).titleString;
			}
			else
			{
				team = AutoTurret(target).team;
				titleString = AutoTurret(target).titleString;
			}
			if ( (bTeamDM && (player.PlayerReplicationInfo.team == team)) ||
				  (!bTeamDM && (player.PlayerReplicationInfo.PlayerID == team)) )
				xcolor = colGreen;
			else if (team == -1)
				xcolor = colWhite;
			else
				xcolor = colRed;

			targetPlayerName = titleString;
			targetOutOfRange = False;
			targetPlayerTime = Player.Level.Timeseconds + targetPlayerDelay;
			targetPlayerColor = xcolor;
		}
		else if ( target.IsA('ComputerSecurity'))
		{
			if ( ComputerSecurity(target).team == -1 )
				xcolor = colWhite;
			else if ((bTeamDM && (ComputerSecurity(target).team==player.PlayerReplicationInfo.team)) ||
						 (bDM && (ComputerSecurity(target).team==player.PlayerReplicationInfo.PlayerID)))
				xcolor = colGreen;
			else
				xcolor = colRed;
		}
		else if ( target.IsA('SecurityCamera'))
		{
         if ( !SecurityCamera(target).bActive )
            xcolor = colWhite;
			else if ( SecurityCamera(target).team == -1 )
				xcolor = colWhite;
			else if ((bTeamDM && (SecurityCamera(target).team==player.PlayerReplicationInfo.team)) ||
						 (bDM && (SecurityCamera(target).team==player.PlayerReplicationInfo.PlayerID)))
				xcolor = colGreen;
			else
				xcolor = colRed;
		}
	}
}


// ----------------------------------------------------------------------
// DrawTargetAugmentation()
// ----------------------------------------------------------------------

function DrawTargetAugmentation(GC gc)
{
	local String str;
	local Actor target;
	local float boxCX, boxCY, boxTLX, boxTLY, boxBRX, boxBRY, boxW, boxH;
	local float x, y, w, h, mult;
	local Vector v1, v2;
	local int i, j, k;
	local DeusExWeapon weapon;
	local bool bUseOldTarget;
	local Color crossColor;
	local DeusExPlayer own;
	local vector AimLocation;
	local int AimBodyPart;

	// Vanilla Matters
	local Crosshair crosshair;

	crosshair = DeusExRootWindow( player.rootWindow ).hud.cross;

	crossColor.R = 255; crossColor.G = 255; crossColor.B = 255;

	// check 500 feet in front of the player
	target = TraceLOS(8000,AimLocation);

	targetplayerhealthstring = "";
	targetplayerlocationstring = "";

	// Vanilla Matters: Rewrite to have the reticle always on if a weapon is out.
	GetTargetReticleColor( target, crossColor );

	weapon = DeusExWeapon( player.Weapon );
	if ( weapon != None && !( weapon.bHandToHand && weapon.bInstantHit ) && !bUseOldTarget ) {
		if ( target != none && VSize( target.Location - Player.Location ) >= weapon.MaxRange ) {
			crossColor = colWhite;
		}

		w = width;
		h = height;
		x = int( w * 0.5 );
		y = int( h * 0.5 );

		mult = FClamp( weapon.currentAccuracy * 50.0 * ( width / 640.0 ), corner, 200 );

		mult = FMax( mult, corner + 4 );
		if ( weapon.currentAccuracy <= 0 ) {
			mult = corner;
		}

		gc.SetTileColorRGB( 0, 0, 0 );
		for ( i = 1; i >= 0; i-- ) {
			gc.DrawBox( x + i, y - mult + i, 1, corner, 0, 0, 1, Texture'Solid' );
			gc.DrawBox( x + i, y + mult - corner + i + 1, 1, corner, 0, 0, 1, Texture'Solid' );
			// gc.DrawBox( x - ( corner - 1 ) / 2 + i, y - mult + i, corner, 1, 0, 0, 1, Texture'Solid' );
			// gc.DrawBox( x - ( corner - 1 ) / 2 + i, y + mult + i, corner, 1, 0, 0, 1, Texture'Solid' );

			gc.DrawBox( x - mult + i, y + i, corner, 1, 0, 0, 1, Texture'Solid' );
			gc.DrawBox( x + mult - corner + i + 1, y + i, corner, 1, 0, 0, 1, Texture'Solid' );
			// gc.DrawBox( x - mult + i, y - ( ( corner - 1 ) / 2 ) + i, 1, corner, 0, 0, 1, Texture'Solid' );
			// gc.DrawBox( x + mult + i, y - ( ( corner - 1 ) / 2 ) + i , 1, corner, 0, 0, 1, Texture'Solid' );

			gc.DrawBox( x + i, y + i, 1, 1, 0, 0, 1, Texture'Solid' );

			gc.SetTileColor( crossColor );
		}

		VM_recticleDrawn = true;
	}
	else {
		VM_recticleDrawn = false;
	}
	
	if ( DeusExMover( target ) != none ) {
		target = None;
	}

	// let there be a 0.5 second delay before losing a target
	if (target == None)
	{
		if ((Player.Level.TimeSeconds - lastTargetTime < 0.5) && IsActorValid(lastTarget))
		{
			target = lastTarget;
			bUseOldTarget = True;
		}
		else
		{
			RemoveActorRef(lastTarget);
			lastTarget = None;
		}
	}
	else
	{
		lastTargetTime = Player.Level.TimeSeconds;
		bUseOldTarget = False;
		if (lastTarget != target)
		{
			RemoveActorRef(lastTarget);
			lastTarget = target;
			AddActorRef(lastTarget);
		}
	}

	if (target != None)
	{
		// Vanilla Matters: Move this here.
		// VM: We're using an unused DXPlayer variable called "own", it does not mean this contains our own player.
		own = DeusExPlayer( target );
		if ( own != none && bTargetActive ) {
			AimBodyPart = own.GetMPHitLocation( AimLocation );
			if ( AimBodyPart == 1 ) {
				TargetPlayerLocationString = "(" $ msgHead $ ")";
			}
			else if ( AimBodyPart == 2 || AimBodyPart == 5 || AimBodyPart == 6 ) {
				TargetPlayerLocationString = "(" $ msgTorso $ ")";
			}
			else if ( AimBodyPart == 3 || AimBodyPart == 4 ) {
				TargetPlayerLocationString = "(" $ msgLegs $ ")";
			}
		}

		// draw a cornered targetting box
		v1.X = target.CollisionRadius;
		v1.Y = target.CollisionRadius;
		v1.Z = target.CollisionHeight;

		if (ConvertVectorToCoordinates(target.Location, boxCX, boxCY))
		{
			boxTLX = boxCX;
			boxTLY = boxCY;
			boxBRX = boxCX;
			boxBRY = boxCY;

			// get the smallest box to enclose actor
			// modified from Scott's ActorDisplayWindow
			for (i=-1; i<=1; i+=2)
			{
				for (j=-1; j<=1; j+=2)
				{
					for (k=-1; k<=1; k+=2)
					{
						v2 = v1;
						v2.X *= i;
						v2.Y *= j;
						v2.Z *= k;
						v2.X += target.Location.X;
						v2.Y += target.Location.Y;
						v2.Z += target.Location.Z;

						if (ConvertVectorToCoordinates(v2, x, y))
						{
							boxTLX = FMin(boxTLX, x);
							boxTLY = FMin(boxTLY, y);
							boxBRX = FMax(boxBRX, x);
							boxBRY = FMax(boxBRY, y);
						}
					}
				}
			}

			boxTLX = FClamp(boxTLX, margin, width-margin);
			boxTLY = FClamp(boxTLY, margin, height-margin);
			boxBRX = FClamp(boxBRX, margin, width-margin);
			boxBRY = FClamp(boxBRY, margin, height-margin);

			boxW = boxBRX - boxTLX;
			boxH = boxBRY - boxTLY;

			if ((bTargetActive) && (Player.Level.Netmode == NM_Standalone))
			{
				// set the coords of the zoom window, and draw the box
				// even if we don't have a zoom window

				// Vanilla Matters: Move the window to the right.
				x = width - ( width / 8 ) - margin;
				y = height / 2;
				w = width / 4;
				h = height / 4;

				DrawDropShadowBox(gc, x-w/2, y-h/2, w, h);

				// Vanilla Matters: Move the window to the right.
				boxCX = width - ( width / 8 ) - margin;
				boxCY = height / 2;

				boxTLX = boxCX - width/8;
				boxTLY = boxCY - height/8;
				boxBRX = boxCX + width/8;
				boxBRY = boxCY + height/8;

				if (targetLevel > 2)
				{
					if (winZoom != None)
					{
						mult = (target.CollisionRadius + target.CollisionHeight);
						v1 = Player.Location;
						v1.Z += Player.BaseEyeHeight;
						v2 = 1.5 * Player.Normal(target.Location - v1);
						winZoom.SetViewportLocation(target.Location - mult * v2);
						winZoom.SetWatchActor(target);
					}
					// window construction now happens in Tick()
				}
				else
				{
					// black out the zoom window and draw a "no image" message
					gc.SetStyle(DSTY_Normal);
					gc.SetTileColorRGB(0,0,0);
					gc.DrawPattern(boxTLX, boxTLY, w, h, 0, 0, Texture'Solid');

					gc.SetTextColorRGB(255,255,255);
					gc.GetTextExtent(0, w, h, msgNoImage);
					x = boxCX - w/2;
					y = boxCY - h/2;
					gc.DrawText(x, y, w, h, msgNoImage);
				}

				// print the name of the target above the box
				if (target.IsA('Pawn'))
					str = target.BindName;
				else if (target.IsA('DeusExDecoration'))
					str = DeusExDecoration(target).itemName;
				else if (target.IsA('DeusExProjectile'))
					str = DeusExProjectile(target).itemName;
				else
					str = target.GetItemName(String(target.Class));

				// print disabled robot info
				if (target.IsA('Robot') && (Robot(target).EMPHitPoints == 0))
					str = str $ " (" $ msgDisabled $ ")";
				gc.SetTextColor(crossColor);

				// print the range to target
				mult = VSize(target.Location - Player.Location);
				str = str $ CR() $ msgRange @ Int(mult/16) @ msgRangeUnits;

				gc.GetTextExtent(0, w, h, str);
				x = boxTLX + margin;
				y = boxTLY - h - margin;
				gc.DrawText(x, y, w, h, str);

				// level zero gives very basic health info
				if (target.IsA('Pawn'))
					mult = Float(Pawn(target).Health) / Float(Pawn(target).Default.Health);
				else if (target.IsA('DeusExDecoration'))
					mult = Float(DeusExDecoration(target).HitPoints) / Float(DeusExDecoration(target).Default.HitPoints);
				else
					mult = 1.0;

				if (targetLevel == 0)
				{
					// level zero only gives us general health readings
					if (mult >= 0.66)
					{
						str = msgHigh;
						mult = 1.0;
					}
					else if (mult >= 0.33)
					{
						str = msgMedium;
						mult = 0.5;
					}
					else
					{
						str = msgLow;
						mult = 0.05;
					}

					str = str @ msgHealth;
				}
				else
				{
					// level one gives exact health readings
					str = Int(mult * 100.0) $ msgPercent;
					if (target.IsA('Pawn') && !target.IsA('Robot') && !target.IsA('Animal'))
					{
						x = mult;		// save this for color calc
						str = str @ msgOverall;
						mult = Float(Pawn(target).HealthHead) / Float(Pawn(target).Default.HealthHead);
						str = str $ CR() $ Int(mult * 100.0) $ msgPercent @ msgHead;
						mult = Float(Pawn(target).HealthTorso) / Float(Pawn(target).Default.HealthTorso);
						str = str $ CR() $ Int(mult * 100.0) $ msgPercent @ msgTorso;
						mult = Float(Pawn(target).HealthArmLeft) / Float(Pawn(target).Default.HealthArmLeft);
						str = str $ CR() $ Int(mult * 100.0) $ msgPercent @ msgLeftArm;
						mult = Float(Pawn(target).HealthArmRight) / Float(Pawn(target).Default.HealthArmRight);
						str = str $ CR() $ Int(mult * 100.0) $ msgPercent @ msgRightArm;
						mult = Float(Pawn(target).HealthLegLeft) / Float(Pawn(target).Default.HealthLegLeft);
						str = str $ CR() $ Int(mult * 100.0) $ msgPercent @ msgLeftLeg;
						mult = Float(Pawn(target).HealthLegRight) / Float(Pawn(target).Default.HealthLegRight);
						str = str $ CR() $ Int(mult * 100.0) $ msgPercent @ msgRightLeg;
						mult = x;
					}
					else
					{
						str = str @ msgHealth;
					}
				}

				gc.GetTextExtent(0, w, h, str);
				x = boxTLX + margin;
				y = boxTLY + margin;
				gc.SetTextColor(GetColorScaled(mult));
				gc.DrawText(x, y, w, h, str);
				gc.SetTextColor(colHeaderText);

				if (targetLevel > 1)
				{
					// level two gives us weapon info as well

					// Vanilla Matters: Let the player see robots' weapon and identifies monsters' weapons as "undefined".
					str = msgWeapon;
	
					if ( Pawn( target ) != None ) {
						if ( !target.IsA( 'Animal' ) ) {
							if ( Pawn( target ).Weapon != None ) {
								str = str @ target.GetItemName( String( Pawn( target ).Weapon.Class ) );
							}
							else {
								str = str @ msgNone;
							}
						}
						else {
							str = str @ VM_msgUndefined;
						}
					}

					gc.GetTextExtent( 0, w, h, str );
					x = boxTLX + margin;
					y = boxBRY - h - margin;
					gc.DrawText( x, y, w, h, str );
				}
			}

			// Vanilla Matters: We display disabled robot state in frob display window instead.
		}
	}
	else if ((bTargetActive) && (Player.Level.NetMode == NM_Standalone))
	{
		if (Player.Level.TimeSeconds % 1.5 > 0.75)
			str = msgScanning1;
		else
			str = msgScanning2;
		gc.GetTextExtent(0, w, h, str);
		x = width/2 - w/2;
		y = (height/2 - h) - 20;
		gc.DrawText(x, y, w, h, str);
	}

	// set the crosshair colors

	// Vanilla Matters
	crosshair.SetCrosshairColor( crossColor );
}

// ----------------------------------------------------------------------
// DrawVisionAugmentation()
// ----------------------------------------------------------------------

// Vanilla Matters: Rewrite because it looked really bad.
function DrawVisionAugmentation( GC gc ) {
	local Vector loc;
	local float dist;
	local float BrightDot;
	local Actor A;
	local float DrawGlow;
	local float RadianView;
	local float OldFlash, NewFlash;
	local vector OldFog, NewFog;
	local Texture oldSkins[9];

	local float saveBrightness;
	local bool heatSource;

	// Vanilla Matters
	local int i;

	visionLevel = 0;
	visionLevelValue = 0;
	for ( i = 0; i < 2; i++ ) {
		if ( VM_visionLevels[i] > 0 ) {
			visionLevel = FMax( visionLevel, VM_visionLevels[i] );
			visionLevelValue = FMax( visionLevelValue, VM_visionValues[i] );
		}
	}

	if ( visionLevel <= 0 ) {
		bVisionActive = false;
	}
	else {
		bVisionActive = true;
	}

	if ( !bVisionActive ) {
		if ( player.Level.Brightness != player.Level.default.Brightness ) {
			player.Level.Brightness = player.Level.default.Brightness;
			player.ConsoleCommand( "FlushLighting" );
		}

		return;
	}

	saveBrightness = player.Level.Brightness;

	if ( visionLevel > 1 ) {
		// Vanilla Matters: Always use the blue overlay because it's better.
		gc.SetStyle( DSTY_Modulated );
		gc.DrawPattern( 0, 0, width, height, 0, 0, Texture'VisionBlue' );
		gc.DrawPattern( 0, 0, width, height, 0, 0, Texture'VisionBlue' );
		gc.SetStyle( DSTY_Translucent );

		loc = player.Location;
		loc.z = loc.z + Player.BaseEyeHeight;

		foreach Player.AllActors( class'Actor', A ) {
			if ( A.bVisionImportant ) {
				heatSource = IsHeatSource( A );
				if ( heatSource || ( player.Level.Netmode != NM_Standalone && ( AutoTurret( A ) != none || AutoTurretGun( A ) != none || SecurityCamera( A ) != none ) ) ) {
					dist = VSize( A.Location - loc );
					VisionTargetStatus = GetVisionTargetStatus( A );
					if ( heatSource && ( ( Player.Level.Netmode != NM_Standalone && dist <= ( visionLevelValue / 2 ) ) || ( Player.Level.Netmode == NM_Standalone && dist <= visionLevelValue ) ) ) {
						SetSkins( A, oldSkins );
						gc.DrawActor( A, False, False, True, 1.0, 2.0, None );
						ResetSkins( A, oldSkins );
					}
					else if ( Player.Level.Netmode != NM_Standalone && VisionTargetStatus == VISIONENEMY && A.Style == STY_Translucent ) {
						if ( dist <= visionLevelValue && player.LineOfSightTo( A, true ) ) {             
							SetSkins( A, oldSkins );
							gc.DrawActor( A, False, False, True, 1.0, 2.0, None );
							ResetSkins( A, oldSkins );
						}
					}
					else if ( Player.LineOfSightTo( A,true ) ) {
						SetSkins( A, oldSkins );

						if ( player.Level.NetMode == NM_Standalone || dist <= ( visionLevelValue * 1.5 ) || VisionTargetStatus != VISIONENEMY ) {
							DrawGlow = 2.0;
						}
						else {
							DrawGlow = 2.0 / ( ( dist / ( visionLevelValue * 1.5 ) ) * ( dist / ( visionLevelValue * 1.5 ) ) );
							DrawGlow = FMax( DrawGlow, 0.15 );
						}

						gc.DrawActor( A, False, False, True, 1.0, DrawGlow, None );
						ResetSkins( A, oldSkins );
					}
				}
				else if ( A != VisionBlinder && player.Level.NetMode != NM_Standalone && ExplosionLight( A ) != none && Player.LineOfSightTo( A,True ) ) {
					BrightDot = Normal( Vector( Player.ViewRotation ) ) dot Normal( A.Location - Player.Location );
					dist = VSize( A.Location - Player.Location );
					if ( dist >= 3000 ) {
						DrawGlow = 0;
					}
					else if ( dist <= 300 ) {
						DrawGlow = 1;
					}
					else {
						DrawGlow = ( 3000 - dist ) / ( 3000 - 300 );
					}

					// Calculate view angle in radians.
					RadianView = (Player.FovAngle / 180) * 3.141593;

					if ( BrightDot >= Cos( RadianView ) && DrawGlow > 0.2 && ( BrightDot * DrawGlow * 0.9 ) > 0.2 ) {
						VisionBlinder = A;
						NewFlash = 10.0 * BrightDot * DrawGlow;
						NewFog = vect( 1000,1000,900)  * BrightDot * DrawGlow * 0.9;
						OldFlash = player.DesiredFlashScale;
						OldFog = player.DesiredFlashFog * 1000;

						// Don't add increase the player's flash above the current newflash.
						NewFlash = FMax( 0,NewFlash - OldFlash );
						NewFog.X = FMax( 0,NewFog.X - OldFog.X );
						NewFog.Y = FMax( 0,NewFog.Y - OldFog.Y );
						NewFog.Z = FMax( 0,NewFog.Z - OldFog.Z );
						player.ClientFlash( NewFlash, NewFog );
						player.IncreaseClientFlashLength( 4.0 * BrightDot * DrawGlow * BrightDot );
					}
				}
			}
		}

		player.Level.Brightness = VM_irBrightness;
	}
	else if ( visionLevel > 0 && player.Level.NetMode == NM_Standalone ) {
		gc.SetStyle( DSTY_Modulated );
		gc.DrawPattern( 0, 0, width, height, 0, 0, Texture'SolidGreen' );
		gc.DrawPattern( 0, 0, width, height, 0, 0, Texture'SolidGreen' );
		gc.SetStyle( DSTY_Normal );

		player.Level.Brightness = VM_nvBrightness;
	}

	if ( player.Level.Brightness != saveBrightness ) {
		player.ConsoleCommand( "FlushLighting" );
	}
}

// ----------------------------------------------------------------------
// IsHeatSource()
// ----------------------------------------------------------------------

function bool IsHeatSource(Actor A)
{
   if ((A.bHidden) && (Player.Level.NetMode != NM_Standalone))
      return False;
   if (A.IsA('Pawn'))
   {
      if (A.IsA('ScriptedPawn'))
         return True;
      else if ( (A.IsA('DeusExPlayer')) && (A != Player) )//DEUS_EX AMSD For multiplayer.
         return True;
      return False;
   }
	else if (A.IsA('DeusExCarcass'))
		return True;   
	else if (A.IsA('FleshFragment'))
		return True;
   else
		return False;
}

// ----------------------------------------------------------------------
// GetGridTexture()
//
// modified from ActorDisplayWindow
// ----------------------------------------------------------------------

function Texture GetGridTexture(Texture tex)
{
	if (tex == None)
		return Texture'BlackMaskTex';
	else if (tex == Texture'BlackMaskTex')
		return Texture'BlackMaskTex';
	else if (tex == Texture'GrayMaskTex')
		return Texture'BlackMaskTex';
	else if (tex == Texture'PinkMaskTex')
		return Texture'BlackMaskTex';
	else if (VisionTargetStatus == VISIONENEMY)         
      return Texture'Virus_SFX';
   else if (VisionTargetStatus == VISIONALLY)
		return Texture'Wepn_Prifle_SFX';
   else if (VisionTargetStatus == VISIONNEUTRAL)
      return Texture'WhiteStatic';
   else
      return Texture'WhiteStatic';
}

// ----------------------------------------------------------------------
// SetSkins()
// 
// copied from ActorDisplayWindow
// ----------------------------------------------------------------------

function SetSkins(Actor actor, out Texture oldSkins[9])
{
	local int     i;
	local texture curSkin;

	for (i=0; i<8; i++)
		oldSkins[i] = actor.MultiSkins[i];
	oldSkins[i] = actor.Skin;

	for (i=0; i<8; i++)
	{
		curSkin = actor.GetMeshTexture(i);
		actor.MultiSkins[i] = GetGridTexture(curSkin);
	}
	actor.Skin = GetGridTexture(oldSkins[i]);
}

// ----------------------------------------------------------------------
// ResetSkins()
// 
// copied from ActorDisplayWindow
// ----------------------------------------------------------------------

function ResetSkins(Actor actor, Texture oldSkins[9])
{
	local int i;

	for (i=0; i<8; i++)
		actor.MultiSkins[i] = oldSkins[i];
	actor.Skin = oldSkins[i];
}

// ----------------------------------------------------------------------
// DrawDropShadowBox()
// ----------------------------------------------------------------------

function DrawDropShadowBox(GC gc, float x, float y, float w, float h)
{
	local Color oldColor;

	gc.GetTileColor(oldColor);
	gc.SetTileColorRGB(0,0,0);
	gc.DrawBox(x, y+h+1, w+2, 1, 0, 0, 1, Texture'Solid');
	gc.DrawBox(x+w+1, y, 1, h+2, 0, 0, 1, Texture'Solid');
	gc.SetTileColor(colBorder);
	gc.DrawBox(x-1, y-1, w+2, h+2, 0, 0, 1, Texture'Solid');
	gc.SetTileColor(oldColor);
}

// ----------------------------------------------------------------------
// VisionTargetStatus()
// ----------------------------------------------------------------------

function int GetVisionTargetStatus(Actor Target)
{
   local DeusExPlayer PlayerTarget;
   local TeamDMGame TeamGame;

   if (Target == None)
      return VISIONNEUTRAL;
   
   if (player.Level.NetMode == NM_Standalone)
      return VISIONNEUTRAL;

   if (target.IsA('DeusExPlayer'))
   {     
      if (target == player)
         return VISIONNEUTRAL;
      
      TeamGame = TeamDMGame(player.DXGame);
      // In deathmatch, all players are hostile.
      if (TeamGame == None)
         return VISIONENEMY;
      
      PlayerTarget = DeusExPlayer(Target);
      
      if (TeamGame.ArePlayersAllied(PlayerTarget,Player))
         return VISIONALLY;
      else
         return VISIONENEMY;
   }
   else if ( (target.IsA('AutoTurretGun')) || (target.IsA('AutoTurret')) )
   {
      if (target.IsA('AutoTurretGun'))
         return GetVisionTargetStatus(target.Owner);
      else if ((AutoTurret(Target).bDisabled))
         return VISIONNEUTRAL;
      else if (AutoTurret(Target).safetarget == Player) 
         return VISIONALLY;
      else if ((Player.DXGame.IsA('TeamDMGame')) && (AutoTurret(Target).team == -1))
         return VISIONNEUTRAL;
      else if ( (!Player.DXGame.IsA('TeamDMGame')) || (Player.PlayerReplicationInfo.Team != AutoTurret(Target).team) )
          return VISIONENEMY;
      else if (Player.PlayerReplicationInfo.Team == AutoTurret(Target).team)
         return VISIONALLY;
      else
         return VISIONNEUTRAL;
   }
   else if (target.IsA('SecurityCamera'))
   {
      if ( !SecurityCamera(target).bActive )
         return VISIONNEUTRAL;
      else if ( SecurityCamera(target).team == -1 )
         return VISIONNEUTRAL;
      else if (((Player.DXGame.IsA('TeamDMGame')) && (SecurityCamera(target).team==player.PlayerReplicationInfo.team)) ||
         ( (Player.DXGame.IsA('DeathMatchGame')) && (SecurityCamera(target).team==player.PlayerReplicationInfo.PlayerID)))
         return VISIONALLY;
      else
         return VISIONENEMY;
   }
   else
      return VISIONNEUTRAL;
}

// ----------------------------------------------------------------------
// ----------------------------------------------------------------------

defaultproperties
{
     margin=4.000000
     corner=9.000000
     msgRange="Range"
     msgRangeUnits="ft"
     msgHigh="High"
     msgMedium="Medium"
     msgLow="Low"
     msgHealth="health"
     msgOverall="Overall"
     msgPercent="%"
     msgHead="Head"
     msgTorso="Torso"
     msgLeftArm="L Arm"
     msgRightArm="R Arm"
     msgLeftLeg="L Leg"
     msgRightLeg="R Leg"
     msgLegs="Legs"
     msgWeapon="Weapon:"
     msgNone="None"
     msgScanning1="* No Target *"
     msgScanning2="* Scanning *"
     msgADSTracking="* ADS Tracking *"
     msgADSDetonating="* ADS Detonating *"
     msgBehind="BEHIND"
     msgDroneActive="Remote SpyDrone Active"
     msgEnergyLow="BioElectric energy low!"
     msgCantLaunch="ERROR - No room for SpyDrone construction!"
     msgLightAmpActive="LightAmp Active"
     msgIRAmpActive="IRAmp Active"
     msgNoImage="Image Not Available"
     msgDisabled="Disabled"
     SpottedTeamString="You have spotted a teammate!"
     YouArePoisonedString="You have been poisoned!"
     YouAreBurnedString="You are burning!"
     TurretInvincibleString="Turrets are only affected by EMP damage!"
     CameraInvincibleString="Cameras are only affected by EMP damage!"
     NeutBurnPoisonString="(Use medkits to instantly neutralize)"
     OnlyString="Only "
     KillsToGoString=" more kills, and "
     KillToGoString=" more kill, and "
     LessThanMinuteString="Less than a minute to go, and "
     LessThanXString1="Less than "
     LessThanXString2=" minutes to go, and "
     LeadsMatchString=" leads the match!"
     TiedMatchString="it's a tied match!"
     WillWinMatchString=" will win the match!"
     OutOfRangeString="(Out of range)"
     LostLegsString="You've lost your legs!"
     DropItem1String="You can use <"
     DropItem2String="> to drop an equipped item."
     msgTeammateHit="You hit your teammate!"
     msgTeamNsf="You're on Team NSF!"
     msgTeamUnatco="You're on Team Unatco!"
     UseString="Use <"
     TeamTalkString="> to send team messages."
     TalkString="> to send regular chat messages."
     YouKilledTeammateString="You killed a teammate!"
     TeamLAMString="You cannot pickup your teammate's grenade!"
     TeamComputerString="That computer already belongs to your team!"
     NoCloakWeaponString="You cannot cloak while a weapon is drawn!"
     TeamHackTurretString="That turret already belongs to your team!"
     KeyNotBoundString="Key Not Bound"
     OutOfAmmoString="Out of Ammo!"
     colRed=(R=255)
     colGreen=(G=255)
     colWhite=(R=255,G=255,B=255)
     VM_nvBrightness=2.500000
     VM_irBrightness=1.500000
     VM_msgUndefined="Undefined"
     VM_msgADSNotEnoughEnergy="* ADS no energy *"
}
