package entities;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import utils.GlobalState;

class Gem extends FlxSprite
{
	var originalColor:FlxColor;
	var targetScale:FlxPoint;

	public var selected(default, set):Bool = false;
	public var gemTypeId:Int;

	var angleTween:FlxTween;
	var colourTween:FlxTween;

	var debugText:FlxText;

	public function new()
	{
		super();

		this.debugText = new FlxText(0, 0, 100, "");

		kill();
	}

	public function init(x:Float, y:Float, targetSize:FlxPoint, padding:FlxPoint, gemFrames:FlxFramesCollection, type:GemType)
	{
		if (this.frames == null)
		{
			var gs = FlxG.plugins.get(GlobalState);
			this.frames = gemFrames;
		}

		this.alive = true;
		this.exists = true;
		this.visible = true;
		this.selected = false;

		this.originalColor = type.color;
		this.color = type.color;
		this.gemTypeId = type.id;

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

		this.debugText.x = this.x;
		this.debugText.y = this.y;
		this.debugText.text = Std.string(this.gemTypeId);
	}

	public function move(x:Float, y:Float, duration:Float, onComplete:FlxTween->Void):FlxTween
	{
		return FlxTween.tween(this, {x: x, y: y}, duration, {onComplete: onComplete});
	}

	override public function draw():Void
	{
		super.draw();
		this.debugText.draw();
	}

	public function set_selected(newSelected)
	{
		if (newSelected)
		{
			startRocking();
			colourTween = FlxTween.color(this, 0.6, this.originalColor, FlxColor.WHITE, {
				type: FlxTweenType.PINGPONG,
				ease: FlxEase.circIn,
			});
		}
		else
		{
			if (angleTween != null)
				angleTween.cancel();
			if (colourTween != null)
				colourTween.cancel();
			this.angle = 0;
			this.color = this.originalColor;
		}
		this.selected = newSelected;
		return newSelected;
	}

	function startRocking()
	{
		angleTween = FlxTween.angle(this, 0, 12, 0.6, {
			type: FlxTweenType.ONESHOT,
			ease: FlxEase.smoothStepOut,
			onComplete: (tw) ->
			{
				if (this.selected)
				{
					angleTween = FlxTween.angle(this, 12, -12, 1.2, {
						type: FlxTweenType.PINGPONG,
						ease: FlxEase.smoothStepInOut,
					});
				}
			}
		});
	}
}

class GemType
{
	public static var RED:GemType = new GemType(0, "tileGrey_04.png", 0xffFF0000);
	public static var GREEN:GemType = new GemType(1, "tileGrey_05.png", 0xff00FF00);
	public static var BLUE:GemType = new GemType(2, "tileGrey_06.png", 0xff0000FF);
	public static var YELLOW:GemType = new GemType(3, "tileGrey_07.png", 0xffFFFF00);
	public static var PURPLE:GemType = new GemType(4, "tileGrey_08.png", 0xffFF00FF);
	public static var ORANGE:GemType = new GemType(5, "tileGrey_09.png", 0xffFFA500);

	public static var ALL:Array<GemType> = [RED, GREEN, BLUE, YELLOW, PURPLE, ORANGE];
	public static var random:() -> GemType = () ->
	{
		return ALL[Math.floor(Math.random() * ALL.length)];
	};

	public var id:Int;
	public var frame:String;
	public var color:FlxColor;

	function new(id:Int, uFrame:String, c:FlxColor)
	{
		this.id = id;
		frame = uFrame;
		color = c;
	}
}
