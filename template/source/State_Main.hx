package ;

import flixel.FlxG;
import flixel.FlxState;

class State_Main extends FlxState
{
	// --
	override public function create():Void
	{
		super.create();
	}//---------------------------------------------------;
	
	// --
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		
		#if debug
		// On keypress "f12" reload JSON parameters and reset game
		// So I can quickly make changes to the json file and see them in action
		Reg.debug_keys();
		#end
	
	}//---------------------------------------------------;
	
}// --