package entities;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import utils.GlobalState;

class Gem extends FlxSprite
{
	var originalColor:FlxColor;
	var targetScale:FlxPoint;

	var selected:Bool = false;
	var timer:Float;

	public function new()
	{
		super();
		kill();
	}

	public function init(x:Float, y:Float, targetSize:FlxPoint, padding:FlxPoint, type:GemType)
	{
		if (this.frames == null)
		{
			var gs = FlxG.plugins.get(GlobalState);
			this.frames = gs.gemFrames;
		}

		this.color = type.color;

		this.alive = true;
		this.exists = true;
		this.visible = true;
		this.selected = false;
		this.color = type.color;
		this.originalColor = type.color;
		var newFrame = this.frames.getByName(type.frame);
		this.frame = newFrame;

		var maxW = Math.max(frame.frame.width, frame.frame.width);
		var maxH = Math.max(frame.frame.height, frame.frame.height);

		// set the scale of the sprite using the size of the newFrame and the padding
		var scaleX = (targetSize.x - padding.x) / maxW;
		var scaleY = (targetSize.y - padding.y) / maxH;
		targetScale = FlxPoint.get(scaleX, scaleY);
		this.scale.set(scaleX, scaleY);

		// set the position of the sprite, including the padding
		this.x = x + padding.x / 2;
		this.y = y + padding.y / 2;

		this.updateHitbox();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (this.selected)
		{
			timer += elapsed;
			var s = 0.0007 * Math.sin(timer * 1.6);
			this.scale.add(s, s);
			this.angle += 0.13 * Math.sin(timer * 1.3);
			this.color = FlxColor.interpolate(originalColor, 0xffffffff, 0.55 + 0.3 * Math.sin(timer * 1.6));
		}

		if (FlxG.mouse.justPressed)
		{
			if (this.overlapsPoint(FlxG.mouse.getPosition()))
			{
				this.selected = !this.selected;
				this.timer = Math.PI;

				this.scale = targetScale.clone();
				this.angle = 0;
				this.color = originalColor;
			}
		}
	}
}

class GemType
{
	public static var RED:GemType = new GemType("tileGrey_04.png", 0xffFF0000);
	public static var GREEN:GemType = new GemType("tileGrey_05.png", 0xff00FF00);
	public static var BLUE:GemType = new GemType("tileGrey_06.png", 0xff0000FF);
	public static var YELLOW:GemType = new GemType("tileGrey_07.png", 0xffFFFF00);
	public static var PURPLE:GemType = new GemType("tileGrey_08.png", 0xffFF00FF);
	public static var ORANGE:GemType = new GemType("tileGrey_09.png", 0xffFFA500);

	public static var ALL:Array<GemType> = [RED, GREEN, BLUE, YELLOW, PURPLE, ORANGE];
	public static var random:() -> GemType = () ->
	{
		return ALL[Math.floor(Math.random() * ALL.length)];
	};

	public var frame:String;
	public var color:FlxColor;

	function new(uFrame:String, c:FlxColor)
	{
		frame = uFrame;
		color = c;
	}
}
