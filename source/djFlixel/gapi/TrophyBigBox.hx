package djFlixel.gapi;

import djFlixel.gui.Gui;
import djFlixel.gfx.Palette_DB32;
import djFlixel.gui.listoption.IListOption;
import djFlixel.gapi.ApiOffline.Trophy;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.FlxSprite;

/**
 * 
 * NOTE: 
 * 
 * + Need to have set the P.image!
 * + Needs to have Reg.api set
 * + End of document for JSON
 * 
 */
class TrophyBigBox extends FlxSpriteGroup implements IListOption<Trophy>
{
	inline static var WIDTH:Int = 200;
	inline static var HEIGHT:Int = 38;
	inline static var THUMB_SIZE:Int = 32;

	var bg:FlxSprite;
	var thumb:FlxSprite;
	
	var name:FlxText;
	var desc:FlxText;
	var type:FlxText;
	
	// :: Needed For Interface::
	var data:Trophy;
	
	var unlocked:Bool = false;
	
	public var isFocused(default, null):Bool;
	public var callbacks:String->Void = null;
	
	// -- These values can be copied to a JSON for easier modification
	public static var P:Dynamic = {
		image: "", // you need to set the image!
		name:  { x:41,  y:4 ,  w:170, colOff:22, colOn:1 },
		desc:  { x:41,  y:16 , w:170, colOff:22, colOn:14 },
		type:  { x:140, y:4 ,  w:60,  colOff:22, colOn:5 },
		imbox: { x:3,   y:3 ,  w:170, col:20 }
	};
	
	//--
	public function new() 
	{
		super();
		
		bg = new FlxSprite(0, 0);
		bg.loadGraphic(P.image, true, WIDTH, HEIGHT);
		bg.animation.frameIndex = 0;
		add(bg);
		// --
		thumb = new FlxSprite(P.imbox.x, P.imbox.y);
		thumb.loadGraphic(Reg.api.SPRITE_SHEET, true, 32, 32);
		thumb.visible = false;
		add(thumb);
		// --
		name = new FlxText(P.name.x, P.name.y, P.name.w, "", 8);
		name.color = Palette_DB32.COL[P.name.colOn];
		add(name);
		//--
		desc = new FlxText(P.desc.x, P.desc.y, P.desc.w, "", 8);
		desc.color = Palette_DB32.COL[P.desc.col];
		add(desc);
		//--
		type = new FlxText(P.type.x, P.type.y, P.type.w, "", 8);
		type.color = Palette_DB32.COL[P.type.col];
		type.alignment = "right";
		add(type);
		//--
		
		// -- Force Graphic change to OFF
		isFocused = true;
		unfocus();
		
	}//---------------------------------------------------;
	
	// --
	public function setData(d:Trophy):Void
	{
		data = d;
		name.text = d.name;
		desc.text = d.desc;
		type.text = d.type;
		thumb.animation.frameIndex = d.imIndex - 1;
		thumb.visible = d.unlocked;
		
		unlocked = d.unlocked;
		
		if (unlocked)
		{
			name.color = Palette_DB32.COL[P.name.colOn];
			desc.color = Palette_DB32.COL[P.desc.colOn];
			type.color = Palette_DB32.COL[P.type.colOn];
		}else {
			name.color = Palette_DB32.COL[P.name.colOff];
			desc.color = Palette_DB32.COL[P.desc.colOff];
			type.color = Palette_DB32.COL[P.type.colOff];
		}
		
	}//---------------------------------------------------;
	
	public function sendInput(inputName:Dynamic):Void
	{
	}//---------------------------------------------------;
	
	public function focus():Void 
	{ 
		if (isFocused) return;
			isFocused = true;
			
		if (callbacks != null) callbacks("optFocus");
		
		if (unlocked) {
			bg.animation.frameIndex = 3;
		}else {
			bg.animation.frameIndex = 1;
		}
	}//---------------------------------------------------;
	public function unfocus():Void
	{ 
		// if (!isFocused) return;
			isFocused = false;
		
		if (unlocked) {
			bg.animation.frameIndex = 2;
		}else {
			bg.animation.frameIndex = 0;
		}
	}//---------------------------------------------------;
	// -
	public inline function getOptionHeight():Int
	{
		return HEIGHT;
	}//---------------------------------------------------;
	
	// -
	public function isSame(data:Trophy):Bool
	{
		return this.data.sid == data.sid;
	}//---------------------------------------------------;
	
	// -- 
	// - GroupAlpha is broken, so do it manually... :/
	override private function set_alpha(Value:Float):Float 
	{
		if (Value < 0) Value = 0;
		if (Value > 1) Value = 1;
		for (i in group) { i.alpha = Value; }
		return alpha = Value;
	}//---------------------------------------------------;	
}// -- end -- //




/* JSON Example::
 
	"trophyBox":{
		"image": "assets/trophy_box.png",
		"name" : { "x" : 41 , "y" : 4,  "w":170, "colOff" : 22, "colOn" : 1  },
		"desc" : { "x" : 41 , "y" : 16, "w":170, "colOff" : 22, "colOn" : 14 },
		"type" : { "x" : 140 , "y" : 4, "w":60,  "colOff" : 22, "colOn" : 5 },
		"imbox": { "x" : 3, "y" : 3, "col":20 }
	}
*/