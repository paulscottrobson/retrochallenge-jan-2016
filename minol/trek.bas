// *************************************************************************************************************
// *************************************************************************************************************
//
//											Star Trek in MINOL Basic
//
// *************************************************************************************************************
// *************************************************************************************************************

:Cursor (12,128)														// Writing here sets the Cursor
:Block  31 																// Memory Block is $1Fxx
:Vdu (Block,254)														// Print arbitrary character string.

// i,j,m,n reserved for general use.

:KlingonCount k 														// Number of klingons remaining.
:Energy e 																// Energy levels
:Torpedoes t 															// Number of torpedoes
:Quadrant q 															// Current Quadrant
:KlingonsNear o 														// Klingons in this sector
:Sector s 																// Position in sector

:WarpRequired 		8 													// Energy per warp
:MoveRequired 		2													// Energy per move.

:MaxEnergy 			250 												// Energy maximum value
:MaxTorpedo			4 													// Torpedo max value

// *************************************************************************************************************
//
//												 Initialise a new game.
// 
// *************************************************************************************************************

2	Vdu = 12 															// Set up $Vdu to print control characters
	(Block,255) = 0
	pr $Vdu,"setup ...."
	(Block,240) = 0 													// Set up offset table.
	(Block,241) = 7
	(Block,242) = 8
*	(Block,243) = 9
	(Block,244) = 255
	(Block,245) = 0
	(Block,246) = 1
	(Block,247) = 0-9
	(Block,248) = 0-8
	(Block,249) = 0-7
	KlingonCount = 0													// Clear count of Klingons.
	i = 0 																// Offset into table
5	n = 0 																// Start with empty
	if !<36; n = n + !/80 + 1											// Maybe add Klingons ?
	KlingonCount = KlingonCount + n 									// add to the Klingon count
	if !<16; n = n + 100 												// Maybe add starbase
	(Block,i) = !/50+1*10+n 											// Store in galactic map with some stars
	i = i + 1:if i<64; goto 5
	Energy = MaxEnergy:Torpedoes = MaxTorpedo 							// Reset energy and torpedoes.
	Quadrant = !/4 														// Initialise quadrant.
	(Block,Quadrant) = 123 												// Easily identified !

// *************************************************************************************************************
//
//													Enter a new Quadrant
//
// *************************************************************************************************************

10 	i = 64 																// Clearing the quadrant
	pr "in_quadrant_";													// Display quadrant message
	n = Quadrant/8*8:Vdu = Quadrant-n+48:pr $Vdu,",";
	Vdu = Quadrant/8+48:pr $Vdu

11	(Block,i) = 0														// Clear quadrant memory
	i = i + 1
	if i#128; goto 11
	n = (Block,Quadrant) 												// This is the H,T,U value
	j = 1 																// Initially writing Klingons
	KlingonsNear = 0													// Number of klingons in sector
12 	if n/10*10=n; goto 14 												// Is the mod 10 value zero, if so done this lot.

13 	i = !/4+64															// Random slot in the quadrant
	if (Block,i) # 0;goto 13 											// If empty, try again.
	(Block,i) = j 														// Put into the quadrant
	n = n - 1 															// Reduce value so mod 10 becomes zero
	if 9<j; goto 12 													// If starbase or star, do another one.
	(Block,j+150) = i 													// Save Klingon position
	(Block,j+160) = !/20+25 											// Set Klingon energy
	j = j + 1 															// Bump the klingon reference number.
	KlingonsNear = KlingonsNear+1 										// One more klingon in this sector
	goto 12 															// Keep trying

14 	n = n / 10 															// Do the next digit
	j = j + 1:if j < 9;j = 10 											// Work out next thing to write there.
	if n#0; goto 12														// Do it for klingons, stars, starbases.

15 	Sector = !/4 														// Find empty sector position
	if (Block,Sector+64) #0 ; goto 15 							
	(Block,Sector+64) = 12 												// Put the enterprise there.

// *************************************************************************************************************
//
//													Get a new command
//
// *************************************************************************************************************

20 	if KlingonCount = 0; goto 245 										// Won if destroyed all the Klingons.
	i = Cursor															// Display energy then prompt
	pr "_",Energy;
	Cursor = i
	pr "e:";
	Cursor = i+5
	Vdu = Torpedoes+'0';
	pr "_t:",$Vdu,">";
	in i 																// Input the command.

*	if i<33;goto 30:if i='s';goto 30 									// Space, Return, S : Short Range Scan
 	if i='l';goto 40 													// L : Long Range Scan
	if i='w';goto 50 													// W : Warp to another quadrant.
	if i='m';goto 60 													// M : Move to another quadrant
	if i='q';goto 70 													// Q : Quit Starfleet.

*	goto 20 															// Unknown command.

// *************************************************************************************************************
//
//												Short range scan
//
// *************************************************************************************************************

30	Vdu=12:pr $Vdu 														// Clear the screen
	i = 0
31 	n = (Block,i+64)													// Read short range scanner
	if n = 0; goto 34 													// If empty, goto next
	if n<9; n = 9 														// Will be 9,10,11,12 for 4 characters
	n = n-9*2+224 														// Make it displayable
	(0,i*2) = n 														// Draw it on the display
	(0,i*2+1) = n+1
34 	i = i+1																// Next cell
	if i#64; goto 31													// Until done whole screen
	call (0,5)															// Get key strok
	pr $Vdu; 															// Clear Screen
	goto 20 															// Get next command.										

// *************************************************************************************************************
//
//													Long Range Scan
//
// *************************************************************************************************************

40 	i = 7 																// This is the row counter, goes 7 4 1
41 	j = 0:pr "__"; 														// This is the column couter, goes 0 1 2

42 	n = i+j																// Direction number
	n = (Block,240+n)													// Convert to an offset.
	n = n + Quadrant 													// Convert to a quadrant

43 	if n<64;goto 44:n = n-64:goto 43									// Force it into range

44	n = (Block,n) 														// Read data from scanner
	m = n/100*100 														// M non zero if starbase.
	n = n - m 															// Remove starbase if any.
	pr n;																// Print the lower 2 digits.
	Cursor = Cursor - 4 												// Cursor back to print starbase
*	Vdu = m/100+'0'														// Print starbase.
	pr $Vdu;
	Cursor = Cursor + 2 												// Skip over 2 digits
	if j#2;pr "!";														// Print vertical bar
	j = j + 1															// Do 3 times
	if j # 3; goto 42

* 	i = i - 3															// Next line down
	pr 																	// New line
	if i < 7; pr "__---+---+---"										// Seperator
	if i < 7; goto 41 													// Go back if not finished
	goto 20																// Get next command.

// *************************************************************************************************************
//
//											Warp to another quadrant
//
// *************************************************************************************************************

50 	if Energy-1<WarpRequired;goto 53 									// Enough energy ?
	pr "dir : ";														// ask direction
	in i 																// read direction
	if 9<i; goto 20														// check in range 0-9
	Quadrant = Quadrant + (Block,240+i) 								// New quadrant
	Energy = Energy - WarpRequired 										// Lose Energy
51 	if Quadrant < 64;goto 52:Quadrant = Quadrant-64:goto 51 			// Force into range
52	goto 10 															// Enter a new quadrant.
53  pr "energy !":goto 20												// Not enough energy

// *************************************************************************************************************
//
//												Move within quadrant
//	
// *************************************************************************************************************

60 	pr "dir : ";														// get direction
	in i
	if 9 < i; goto 20 													// bad direction.
	i = (Block,240+i)													// convert direction to offset
	pr "warp: ";														// input warp, e.g. number of moves
	in j
	if 8 < j; goto 20 													// too far.
	(Block,Sector+64) = 0												// erase enterprise.

61 	if j = 0;goto 65													// if done enough, Klingons attack
	if Energy-1 < MoveRequired;goto 65 									// Not enough energy, Klingons attack
	j = j - 1															// decrement move count
	Energy = Energy - MoveRequired										// take away movement energy
	Sector = Sector + i 												// move in appropriate direction.

62 	if Sector < 64;goto 63:Sector = Sector - 64:goto 62 				// Wrap sector around.

63 	n = (Block,Sector+64)												// Read what's there.
	if n = 0 ; goto 61 													// Okay if empty
	if n < 10; goto 240 												// Hit a klingon - both blow up !
	if n = 10; goto 241 												// Hit a star

	pr "starbase_dock"													// Have docked at starbase.
	Energy = MaxEnergy													// Reset energy and torpedoes
	Torpedoes = MaxTorpedo
																		// Drop through to put enterprise back and attack
65 	(Block,Sector+64) = 12:goto 200										// Put enterprise back, and do klingon attack

// *************************************************************************************************************
//
//												Quit Starfleet
//
// *************************************************************************************************************

70 	pr "sure_? ";														// check you do
	in  i
	if 	i = 'y'; goto 242												// if you do, resign
	goto 20																// else do nothing.



200 pr "klingons_!":goto 20												// Klingon attack stuff.

240 pr "collide_klingon":end
241 pr "collide_star":end
242 pr "resign":end
//243 pr "shot_starbase":end
//244 pr "klingon_destroyed_you":end
245 pr "won !":end