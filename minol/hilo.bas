//
//		Hi-lo game, testing.
//
:Guesses 	s
:Number 	x
:Name 		(14,1)

10 	"number
20 	pr
	pr	"what is your name";
	in $Name

30 	Number = 42:Guesses = 0									// new game
	pr "hi ",$Name," welcome to the game of number"
* 	pr "i am thinking of a number from 0 to 255"
* 	pr "guess my number"

60 	pr:pr "your guess ";:in g:Guesses = Guesses + 1			// main game loop.
65 	if g=Number; goto 90
70 	if g<Number; pr "too small."
80	if Number<g; pr "too large"
85 	goto 60

90 	pr "that's right ",$(14,1)," you got it in",Guesses;"guesses"

100 pr "play again ";:in a:if a = 'y'; goto 30
110 pr "okay, hope you had fun":end

