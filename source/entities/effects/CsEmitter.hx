package entities.effects;

import flixel.FlxG;
import flixel.effects.particles.FlxParticle;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxPool;
import utils.ExtendedLerp.ExtendedLerpStop;
import utils.ExtendedLerp;

class CsEmitter extends FlxPool<CsParticle>
{
	public var activeMembers:FlxGroup;

	public function new()
	{
		super(() -> new CsParticle());
		preAllocate(500);
		activeMembers = new FlxGroup();
	}

	public function burstEmit(x:Float, y:Float, amount:Int, color:FlxColor, ?onComplete:() -> Void)
	{
		for (i in 0...amount)
		{
			var particle = this.get();
			activeMembers.add(particle);
			particle.reset(x, y);

			particle.onComplete = onComplete;

			var radiiMax = 600;

			var initVel = FlxPoint.get(FlxG.random.float(-1, 1), FlxG.random.float(-1, 1)).normalize() * FlxG.random.float(0.5, 1) * radiiMax;
			particle.velocityRange.set(initVel, initVel.clone() * 0.1);

			particle.scaleRange.set(FlxPoint.get(1, 1), FlxPoint.get(0.25, 0.25));

			particle.colorRange.set(color, color.getDarkened(0.6));
			particle.alphaRange.active = false;
			particle.alphaExtended = [
				{
					t: 0,
					value: 1
				},
				{
					t: 0.8,
					value: 0.7
				},
				{
					t: 1,
					value: 0
				}
			];

			particle.lifespan = FlxG.random.float(1, 1.5);

			particle.onComplete = () ->
			{
				if (onComplete != null)
					onComplete();
				activeMembers.remove(particle, true);
				particle.kill();
			};
		}
	}

	public function emit(x:Float, y:Float, amount:Int, onComplete:() -> Void, customUpdate:() -> Void)
	{
		var particle:CsParticle;
		for (i in 0...amount)
		{
			particle = this.get();
			particle.x = x;
			particle.y = y;
			// particle.onComplete = onComplete;
			// particle.customUpdate = customUpdate;
			particle.revive();
		}
	}
}

class CsParticle extends FlxParticle
{
	public var onComplete:() -> Void;
	public var customUpdate:() -> Void;

	public var alphaExtended:Array<ExtendedLerpStop>;

	public function new()
	{
		super();
		makeGraphic(10, 10, 0xFFFFFFFF);
		kill();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (alphaExtended != null)
		{
			this.alpha = ExtendedLerp.lerp(alphaExtended, age / lifespan);
		}

		if (customUpdate != null)
		{
			customUpdate();
		}

		if (onComplete != null && !alive)
		{
			onComplete();
		}
	}
}
