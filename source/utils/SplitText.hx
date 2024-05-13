package utils;

import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

typedef Options =
{
	size:Int,
	perCharBuffer:Float,
}

class SplitText extends FlxTypedGroup<FlxText>
{
	public var x(default, set):Float;
	public var y(default, set):Float;
	public var width:Float;
	public var height:Float;

	public var onMouseIn:Void->Void;
	public var onMouseOut:Void->Void;
	public var onClick:Void->Void;

	private var lastMouseOver:Bool;

	public var rect(get, never):FlxRect;

	function get_rect():FlxRect
	{
		return new FlxRect(x, y, width, height);
	}

	function set_x(value:Float):Float
	{
		x = value;
		var acculumX:Float = value;
		var lastWidth:Float = 0;
		for (i in 0...members.length)
		{
			var char = members[i];
			char.x = acculumX - options.perCharBuffer;
			acculumX += char.width - options.perCharBuffer;
			lastWidth = char.width - options.perCharBuffer;
		}

		width = acculumX - value + lastWidth;
		return value;
	}

	function set_y(value:Float):Float
	{
		y = value;
		for (i in 0...members.length)
		{
			members[i].y = value;
		}
		return value;
	}

	public var color(default, set):FlxColor;

	function set_color(value:FlxColor):FlxColor
	{
		color = value;
		for (i in 0...members.length)
		{
			members[i].color = value;
		}
		return value;
	}

	public var alpha(default, set):Float;

	function set_alpha(value:Float):Float
	{
		alpha = value;
		for (i in 0...members.length)
		{
			members[i].alpha = value;
		}
		return value;
	};

	public var borderColor(default, set):FlxColor;
	public var borderSize(default, set):Int;
	public var borderQuality(default, set):Int;
	public var borderStyle(default, set):FlxTextBorderStyle;

	function set_borderColor(value:FlxColor):FlxColor
	{
		borderColor = value;
		for (i in 0...members.length)
		{
			members[i].borderColor = value;
		}
		return value;
	}

	function set_borderSize(value:Int):Int
	{
		borderSize = value;
		for (i in 0...members.length)
		{
			members[i].borderSize = value;
		}
		return value;
	}

	function set_borderQuality(value:Int):Int
	{
		borderQuality = value;
		for (i in 0...members.length)
		{
			members[i].borderQuality = value;
		}
		return value;
	}

	function set_borderStyle(value:FlxTextBorderStyle):FlxTextBorderStyle
	{
		borderStyle = value;
		for (i in 0...members.length)
		{
			members[i].borderStyle = value;
		}
		return value;
	}

	private var options:Options;
	private var originalText:String;

	public function new(X:Float, Y:Float, text:String, ?options:Options)
	{
		super();
		originalText = text;
		color = FlxColor.WHITE;

		this.options = options != null ? options : defaultOptions;

		// Split the text into an array of characters
		var characters:Array<String> = text.split("");

		for (i in 0...characters.length)
		{
			var char = new FlxText(0, 0, -1, characters[i], this.options.size);
			add(char);
		}

		x = X;
		y = Y;
		height = members[0].height;

		onMouseIn = null;
		onMouseOut = null;
		onClick = null;
		lastMouseOver = false;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (onMouseIn != null || onMouseOut != null || onClick != null)
		{
			var mouseOver = rect.containsPoint(FlxG.mouse.getPosition());

			if (mouseOver)
			{
				if (active && FlxG.mouse.justPressed)
				{
					if (onClick != null)
					{
						onClick();
					}
				}
				else if (!lastMouseOver && onMouseIn != null)
				{
					onMouseIn();
				}
			}
			else
			{
				if (lastMouseOver && onMouseOut != null)
				{
					onMouseOut();
				}
			}

			lastMouseOver = mouseOver;
		}
	}

	private var tweens:Array<FlxTween> = [];

	public function animateWave(?totalDistance:Float = 12, ?charDelay:Float = 0.15, ?speed:Float = 1, ?oneShot:Bool = false)
	{
		for (i in 0...members.length)
		{
			var char = members[i];
			var t = FlxTween.tween(char, {y: y - totalDistance / 2}, speed / 2, {
				type: ONESHOT,
				ease: FlxEase.smoothStepOut,
				startDelay: i * charDelay,
				onComplete: (t) ->
				{
					tweens.remove(t);
					if (oneShot)
					{
						var tx = FlxTween.tween(char, {y: y}, speed / 2, {type: ONESHOT, ease: FlxEase.smoothStepInOut});
						tweens.push(tx);
						return;
					}
					var tx = FlxTween.tween(char, {y: y + totalDistance}, speed, {type: PINGPONG, ease: FlxEase.smoothStepInOut});
					tweens.push(tx);
				}
			});
			tweens.push(t);
		}
	}

	public function animateColour(toColor:FlxColor, charDelay:Float = 0.15, ?speed:Float = 1)
	{
		for (i in 0...members.length)
		{
			var char = members[i];
			var t = FlxTween.color(char, speed / 2, color, toColor, {
				type: ONESHOT,
				ease: FlxEase.smoothStepOut,
				startDelay: i * charDelay,
				onComplete: (t) ->
				{
					tweens.remove(t);
					var tx = FlxTween.color(char, speed / 2, toColor, color, {type: ONESHOT, ease: FlxEase.smoothStepInOut});
					tweens.push(tx);
					return;
				}
			});
			tweens.push(t);
		}
	}

	public function stopAnimation()
	{
		for (t in tweens)
		{
			t.cancel();
			y = y;
			color = color;
		}
	}

	public static var defaultOptions:Options = {
		size: 48,
		perCharBuffer: 4,
	};

	public static function naiieveScaleDefaultOptions(scale:Float):Options
	{
		return {
			size: Math.round(defaultOptions.size * scale),
			perCharBuffer: defaultOptions.perCharBuffer * scale,
		};
	}
}
