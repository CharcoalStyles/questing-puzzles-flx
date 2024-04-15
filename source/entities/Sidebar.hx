package entities;

import entities.Gem.GemType;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.effects.particles.FlxEmitter;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxPool;

class Sidebar extends FlxGroup
{
	var allStores:Array<{bar:FlxBar, label:FlxText, particles:FlxPool<Mparticle>}>;
	var isLeft:Bool;

	public function new(isLeft:Bool)
	{
		super();
		this.isLeft = isLeft;

		var background:FlxSprite = new FlxSprite(0, 0);
		var height = Std.int(Math.min(FlxG.height, FlxG.width));
		var width = Std.int((Math.max(FlxG.height, FlxG.width) - height) / 2);

		background.makeGraphic(width, height, 0xff303030);
		background.x = isLeft ? 0 : FlxG.width - width;
		background.y = 0;

		add(background);

		var profile:FlxSprite = new FlxSprite(0, 0);
		profile.makeGraphic(100, 100, isLeft ? FlxColor.GREEN : FlxColor.RED);

		profile.x = isLeft ? 0 : FlxG.width - profile.width;

		add(profile);

		var workingY = 110;
		var paddingY = 5;

		var offsetX = 32;

		allStores = new Array();

		var i = 0;

		var baseX = isLeft ? 0 : FlxG.width - width;

		for (gt in GemType.ALL)
		{
			var label:FlxText = new FlxText(baseX, workingY, 16, gt.shortName);
			label.setFormat(null, 12, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			label.borderSize = 2;
			add(label);

			var bar:FlxBar = new FlxBar(baseX + 24, workingY, FlxBarFillDirection.LEFT_TO_RIGHT, 100, Std.int(label.height));
			bar.createFilledBar(0xff606060, gt.color, true, gt.color);
			add(bar);

			label = new FlxText(baseX + 130, workingY, 64, "0/100");
			label.setFormat(null, 12, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			label.borderSize = 2;
			add(label);

			var em = new FlxPool<Mparticle>(() ->
			{
				var p = new Mparticle(0, 0, gt.color);
				add(p);
				return p;
			});
			em.preAllocate(20);

			allStores.push({
				bar: bar,
				label: label,
				particles: em
			});

			workingY += Math.ceil(bar.height + paddingY);

			i++;
		}
	}

	public function addMana(gemTypeIndex:Int, amount:Int, origin:FlxPoint)
	{
		var store = allStores[gemTypeIndex];
		var bar = store.bar;
		var em = store.particles;
		var subParts = 1;
		var partScale = 1.5;

		if (amount < 3)
		{
			subParts = 4;
			partScale = 0.6;
		}
		else if (amount < 7)
		{
			subParts = 2;
			partScale = 0.9;
		}

		for (i in 0...amount * subParts)
		{
			em.get().emit(origin, new FlxPoint(bar.x, bar.y), partScale, () ->
			{
				bar.value += amount / subParts;
				store.label.text = Std.string(Math.floor(bar.value)) + "/100";
			});
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}

class Mparticle extends FlxSprite
{
	var timer:Float = 0.0;
	var timerTrigger:Float = 0.5;
	var triggered:Bool = false;
	var target:FlxPoint;
	var onComplete:() -> Void;

	public function new(x:Float, y:Float, color:Int)
	{
		super(x, y);
		makeGraphic(10, 10, color);
		kill();
	}

	public function emit(o:FlxPoint, t:FlxPoint, scale:Float, onComplete:() -> Void)
	{
		super.reset(o.x, o.y);
		target = t;
		this.onComplete = onComplete;
		this.scale.set(scale, scale);
		angle = FlxG.random.float(0, 360);
		velocity.x = FlxG.random.float(-10, 10) * 10;
		velocity.y = FlxG.random.float(-10, 10) * 10;
		this.angularVelocity = FlxG.random.sign() * FlxG.random.float(45, 180);
		timer = 0.0;
		timerTrigger = FlxG.random.float(0.4, 0.6);
		triggered = false;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		timer += elapsed;
		if (!triggered && timer > timerTrigger)
		{
			triggered = true;
			var tweenTime = timerTrigger * 2;

			FlxTween.tween(this.scale, {x: 0.5, y: 0.5}, tweenTime);
			FlxTween.quadMotion(this, x, y, x + FlxG.random.float(-10, 10), y + FlxG.random.float(-10, 10), target.x, target.y, tweenTime, true, {
				onComplete: (t) ->
				{
					onComplete();
					kill();
				}
			});
		}
	};
}
