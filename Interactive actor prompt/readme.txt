Uses an EventHandler to print a text-based prompt on the player's screen when they look at a certain actor.

This can be used to create interaction prompts like "Press X to Y" and such.

Determining what makes an actor "interactive" is up to you: for this purpose, there's a isActorInteractable(Actor thing) boolean function, which you can modify to add your own conditions.