package entities;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import utils.GlobalState;

class Gem extends FlxSprite
{
	public static var count:Int = 0;

	public var id:Int;

	var originalColor:FlxColor;
	var targetScale:FlxPoint;

	public var selected(default, set):Bool = false;
	public var highlighted(default, set):Bool = false;
	public var manaType:ManaType;

	var angleTween:FlxTween;
	var colourTween:FlxTween;

	var debugText:FlxText;

	public function new()
	{
		super();
		this.id = Gem.count;
		Gem.count++;

		this.debugText = new FlxText(0, 0, 100, "");
		this.debugText.setFormat(null, 8, 0xffffffff, "left", FlxTextBorderStyle.OUTLINE_FAST, 0xff101010);

		kill();
	}

	public function setType(type:GemType)
	{
		this.originalColor = type.color;
		this.color = type.color;
		this.manaType = type.manaType;

		this.frame = this.frames.getByName(type.frame);
	}

	public function respawn(x:Float, y:Float, type:GemType)
	{
		this.x = x;
		this.y = y;

		this.alive = true;
		this.exists = true;
		this.visible = true;
		this.selected = false;

		if (angleTween != null)
			angleTween.cancel();
		if (colourTween != null)
		{
			colourTween.cancel();
		}

		setType(type);
	}

	public function init(x:Float, y:Float, targetSize:FlxPoint, padding:FlxPoint, gemFrames:FlxFramesCollection, type:GemType)
	{
		if (this.frames == null)
		{
			var gs = FlxG.plugins.get(GlobalState);
			this.frames = gemFrames;
		}

		// set the position of the sprite, including the padding
		var targetX = x + padding.x / 2;
		var targetY = y + padding.y / 2;

		this.respawn(targetX, targetY, type);

		var maxW = Math.max(frame.frame.width, frame.frame.width);
		var maxH = Math.max(frame.frame.height, frame.frame.height);

		// set the scale of the sprite using the size of the newFrame and the padding
		var scaleX = (targetSize.x - padding.x) / maxW;
		var scaleY = (targetSize.y - padding.y) / maxH;
		targetScale = FlxPoint.get(scaleX, scaleY);
		this.scale.set(scaleX, scaleY);

		this.updateHitbox();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		this.debugText.x = this.x;
		this.debugText.y = this.y;
		this.debugText.text = Std.string(this.manaType);
	}

	public function move(x:Float, y:Float, duration:Float, onComplete:FlxTween->Void, ?ease:EaseFunction):FlxTween
	{
		return FlxTween.tween(this, {x: x, y: y}, duration, {onComplete: onComplete, ease: ease != null ? ease : FlxEase.linear});
	}

	override public function draw():Void
	{
		super.draw();
		// this.debugText.draw();
	}

	public function set_selected(newSelected)
	{
		if (newSelected)
		{
			if (colourTween != null)
				colourTween.cancel();
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

	function set_highlighted(value:Bool):Bool
	{
		if (value)
		{
			colourTween = FlxTween.color(this, 0.3, this.originalColor, FlxColor.WHITE, {
				type: FlxTweenType.PINGPONG,
				ease: FlxEase.quintInOut,
			});
		}
		else
		{
			if (colourTween != null)
				colourTween.cancel();
			this.color = this.originalColor;
		}
		return value;
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

enum ManaType
{
	FIRE;
	EARTH;
	WATER;
	AIR;
	LIGHT;
	DARK;
}

class GemType
{
	public static var RED:GemType = new GemType(ManaType.FIRE, "tileGrey_40.png", 0xfffa9189, "Fire");
	public static var GREEN:GemType = new GemType(ManaType.EARTH, "tileGrey_41.png", 0xffb3f5bc, "Earth");
	public static var BLUE:GemType = new GemType(ManaType.WATER, "tileGrey_42.png", 0xffd6f6ff, "Water");
	public static var YELLOW:GemType = new GemType(ManaType.LIGHT, "tileGrey_33.png", 0xfff9ffb5, "Light");
	public static var PURPLE:GemType = new GemType(ManaType.DARK, "tileGrey_32.png", 0xffd1bdff, "Dark");
	public static var ORANGE:GemType = new GemType(ManaType.AIR, "tileGrey_31.png", 0xffaaaaaa, "Air");

	public static var ALL:Array<GemType> = [RED, GREEN, BLUE, YELLOW, PURPLE, ORANGE];
	public static var random = (?notIds:Array<ManaType>) ->
	{
		var filtered = ALL.filter((gt) -> (notIds == null ? [] : notIds).indexOf(gt.manaType) == -1);
		return filtered[Math.floor(Math.random() * filtered.length)];
	};

	public static var fromManaType = (mt:ManaType) ->
	{
		var idx = ALL.filter((gt) -> gt.manaType == mt);
		return idx.length > 0 ? idx[0] : null;
	};

	public var manaType:ManaType;
	public var frame:String;
	public var color:FlxColor;
	public var name:String;
	public var shortName:String;

	function new(mt:ManaType, uFrame:String, c:FlxColor, n:String)
	{
		manaType = mt;
		frame = uFrame;
		color = c;
		name = n;
		shortName = n.substring(0, 1);
	}
}
