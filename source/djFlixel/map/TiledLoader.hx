/**
 * General purpose TiledMap loader
 * =======================
 * 
 * Example
 * ========
 *
 * var mapData = new TiledLoader();
 *     mapData.load("assets/map.tmx");
 * 
 * Notes:
 * ========
 *
 * .Usage example in  RD52 game project
 * 
 *----------------------------------------------------------*/


package djFlixel.map;

import djFlixel.tool.DynAssets;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import haxe.xml.Fast;
import openfl.Assets;


// Data structure for a floating map entity
typedef MapEntity = {
	x:Int,
	y:Int,
	id:Int,
	?type:String,
	?uid:Int
};


/**
 * Easy Customizable TiledMap Editor Loader.
 * Just the DATA.
 * 
 * NOTES:
 * -----
 * Assumes ONE image per Layer, else it WILL break.
 * 
 * USAGE:
 * -------
 * 
 * 	mapLoader = new TiledLoader();
 *	mapLoader.load("assets/maps/level_01.tmx");
 *	var mapData:Array<Int> = mapLoader.layerTiles.get("tiles");
 *  
 * 
 * @author JohnDimi, @jondmt
 */
class TiledLoader implements IFlxDestroyable
{
	
	static var ASSETS_PATH:String = "assets/";
	
	public var layerTiles:Map<String,Array<Array<Int>>>;	// LayerName=> Array
	public var layerEntities:Map<String,Array<MapEntity>>; 	// LayerName=> Entities
	
	// Store the sizes of all the layers, in case I need them later
	public var tilesetWidths(default,null):Map<String,Int>;
	
	public var bgColor(default, null):Int = 0xFF000000; // TODO: Load this from the file
	
	public var tileWidth(default, null):Int;
	public var tileHeight(default, null):Int;
	
	public var mapWidth(default, null):Int; 	// in tiles
	public var mapHeight(default, null):Int;	// in tiles

	// The currently loaded map file.
	public var mapID(default, null):String;
	
	//---------------------------------------------------;
	public function new() 
	{	
	}//---------------------------------------------------;
	
	public function destroy()
	{
		layerTiles = null;
		layerEntities = null;
		tilesetWidths = null;
	}//---------------------------------------------------;
	
	/**
	 * Load a .TMX map file. ( IT MUST EXIST IN THE EMBEDDED ASSETS! )
	 * @param	file The file to load
	 * @param	sameImagesLayer If any layer shares an image with another layer, put the name of the layer here. #offset correction hack
	 */
	public function load(file:String, ?sameImagesLayer:Array<String>)
	{
		trace('Loading map file ($file)');
	
		mapID = file;
		
		layerTiles = new Map();
		layerEntities = new Map();
		tilesetWidths = new Map();
		
		if (sameImagesLayer == null) sameImagesLayer = [];
		
		// ---
		var root:Fast;
		
		// This objects supports Dynamic Files with the "DynAssets.hx' class
		// If a dynamic load fails, it will try to load from embedded
		try {
			
		#if (EXTERNAL_LOAD)
			if (DynAssets.files.exists(file)) {
				trace("++ Loading map dynamically");
				root = new Fast(Xml.parse(DynAssets.files.get(file))).node.resolve("map");
			}else {	
				trace('Error: Can\'t load "$file" dynamically. Push it to the dynamic file list. !!');
		#end
			trace("++ Loading from embedded");
			root = new Fast(Xml.parse(Assets.getText(ASSETS_PATH + file))).node.resolve("map");

		#if (EXTERNAL_LOAD)
			}
		#end
		
		}catch (e:Dynamic){
			trace('Fatal: Map file ($file) does not exist');
			throw "Fatal: Map file ($file) does not exist";
			return;
		}
		
		mapWidth   = Std.parseInt(root.att.resolve("width"));
		mapHeight  = Std.parseInt(root.att.resolve("height"));
		tileWidth  = Std.parseInt(root.att.resolve("tilewidth"));
		tileHeight = Std.parseInt(root.att.resolve("tileheight"));

		// --
		var tnode:Fast;
		var r1:Int = 0;
		var offset:Int;
		var layerName:String;
		
		// 1: First thing is to read the tileoffsets for the layers
		var tileOffsets:Array<Int> = [];
		for (tnode in root.nodes.tileset)
		{
			tileOffsets.push(Std.parseInt(tnode.att.resolve("firstgid")) - 1);
			// trace("Reading offset ", tileOffsets[tileOffsets.length - 1]);
			// new: get tilesets
			tilesetWidths.set(tnode.att.name, Std.parseInt(tnode.att.tilewidth));
		}
		
		// 2: Read the layers
		for (tnode in root.nodes.layer)
		{
			 layerName = tnode.att.resolve("name");
			
			if (sameImagesLayer.indexOf(layerName) >= 0){
				offset = -tileOffsets[0];
			}else {	
				offset = -tileOffsets.shift();
			}
			
			layerTiles.set(layerName, CSVToArrayInt(tnode.node.data.innerData, offset));
			
			trace("Reading layer -- " + layerName);
			// trace("Set with data --", layerTiles.get(layerName));
		}
		
		// 3: Read the Entities
		for (tnode in root.nodes.objectgroup)
		{
			layerName = tnode.att.resolve("name");
			
			if (sameImagesLayer.indexOf(layerName) >= 0) {
				offset = -tileOffsets[0];
			}else {	
				offset = -tileOffsets.shift();
			}
			
			var tempArray:Array<MapEntity> = readObjectLayer(tnode, offset);
			
			if (tempArray != null)
			{
				layerEntities.set(layerName, tempArray);
				trace("Reading Object layer -- " + layerName);
			}
		}
	}//---------------------------------------------------;
	
	
	// --
	// Quickly read an object layer and return an array containing it's data
	function readObjectLayer(dataNode:Fast, idOffset:Int = 0):Array<MapEntity>
	{
		//-- Old code: Read a specific layer
		//var r1 = dataNode.nodes.objectgroup.filter(function(_) { return (_.att.name == layerName); } ).first();
		//if (r1 == null) return null; // Not found!
		
		if (!dataNode.hasNode.object)
		{
			trace("Waning: Entity layer contains NO entities");
			return null;
		}
		
		// - Check to see if it's a geom layer
		if (dataNode.node.object.hasNode.polyline)
		{
			trace("This is a polygon layer, skipping [X]");
			return null;
		}
		
		var ar = new Array<MapEntity>();
		var node:Fast;
		var r2:String;

		for (node in dataNode.nodes.object)
		{
			try {
				r2 = node.att.type;
			} catch (error:String) {
				r2 = null;
			}

			ar.push ({ 	x:Std.parseInt(node.att.x),
						y:Std.parseInt(node.att.y) - Std.parseInt(node.att.height), // FIX A BUG from the Tiled Editor
						id:Std.parseInt(node.att.gid) + idOffset,
						type:r2
					});
		}
		
		return ar;
	}//---------------------------------------------------;
	
	// --
	// Convert the CSV string read from the map to an array,
	// with an optional applied offset.
	function CSVToArrayInt(csv:String, offset:Int = 0):Array<Array<Int>>
	{
		var ar_final = new Array<Array<Int>>();
		var ar_csv = csv.split(',');
		
		var r1:Int;
		var seqRead:Int = 0;
		
		for (yy in 0...mapHeight)
		{
			ar_final[yy] = [];
			
			for (xx in 0...mapWidth)
			{
				r1 = Std.parseInt(ar_csv[seqRead]);
				if (r1 > 0) r1 += offset;
				seqRead++;
				ar_final[yy][xx] = r1;
			}
		}

		return ar_final;
	}//---------------------------------------------------;
	
	
	
	
	
	
	
}//-- end class --//