//
//		Hi-lo game, testing.
//
10 	"number
20 	pr
	pr	"what is your name";
	in  $(14,1)

30 	x = 42:s = 0											// new game
	pr "hi ",$(14,1)," welcome to the game of number"
* 	pr "i am thinking of a number from 0 to 255"
* 	pr "guess my number"

60 	pr:pr "your guess ";:in g:s = s + 1						// main game loop.
65 	if g=x; goto 90
70 	if g<x; pr "too small."
80	if x<g; pr "too large"
85 	goto 60

90 	pr "that's right ",$(14,1)," you got it in",s;"guesses"

100 pr "play again ";:in a:if a = 'y'; goto 30
110 pr "okay, hope you had fun":end

