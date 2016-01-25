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

// i,j,n reserved for general use.

:KlingonCount k 														// Number of klingons remaining.
:Energy e 																// Energy levels
:Torpedoes t 															// Number of torpedoes
:Quadrant q 															// Current Quadrant
:KlingonsNear l 														// Klingons in this sector
:Sector s 																// Position in sector

// *************************************************************************************************************
//
//												 Initialise a new game.
// 
// *************************************************************************************************************

2	(Block,254) = 12 													// Set up $Vdu to print control characters
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
	Energy = 255:Torpedoes = 4 											// Reset energy and torpedoes.
	Quadrant = !/4 														// Initialise quadrant.

// *************************************************************************************************************
//
//													Enter a new Quadrant
//
// *************************************************************************************************************

10 	i = 64 																// Clearing the quadrant
	pr "in_quadrant_";													// Display quadrant message
	n = Quadrant/8*8:(Block,254) = Quadrant-n+48:pr $Vdu,",";
	(Block,254) = Quadrant/8+48:pr $Vdu

11	(Block,i) = 0														// Clear quadrant memory
	i = i + 1
	if i#128; goto 11
	n = (Block,Quadrant) 												// This is the H,T,U value
	n = 123
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

20 	i = Cursor															// Display energy then prompt
	pr "_",Energy;
	Cursor = i
	pr "e:";
	Cursor = i+5
	pr ">";																// Input the command.
	in i 
*	if i<33;goto 30:if i='S';goto 30 									// Space, Return, S : Short Range Scan
*	goto 20 															// Unknown command.

// *************************************************************************************************************
//
//												Short range scan
//
// *************************************************************************************************************

30	(Block,254)=12:pr $Vdu 												// Clear the screen
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
	pr $Vdu 															// Clear Screen
	goto 20 															// Get next command.										