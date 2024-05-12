package entities.effects;

import flixel.FlxG;
import flixel.effects.particles.FlxParticle;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxPool;
import utils.ExtendedLerp;

typedef ParticleProps =
{
	?lifespan:() -> Float,
	?accelerationExtended:() -> Array<ExtendedLerpStop<FlxPoint>>,
	?angularVelocityExtended:() -> Array<ExtendedLerpStop<Float>>,
	?velocityExtended:() -> Array<ExtendedLerpStop<FlxPoint>>,
	?scaleExtended:() -> Array<ExtendedLerpStop<FlxPoint>>,
	?colourExtended:() -> Array<ExtendedLerpStop<FlxColor>>,
	?alphaExtended:() -> Array<ExtendedLerpStop<Float>>,
	?onComplete:(particle:CsParticle) -> Void,
	?customUpdate:(particle:CsParticle) -> Void,
	?target:(particle:CsParticle) -> TargetProps
}

typedef TargetProps =
{
	origin:FlxPoint,
	target:FlxPoint,
	?easeName:String,
}

typedef ParticleSequence = Array<ParticleProps>;

class CsEmitter extends FlxPool<CsParticle>
{
	public var activeMembers:FlxGroup;

	public function new()
	{
		super(() -> new CsParticle());
		preAllocate(500);
		activeMembers = new FlxGroup();
	}

	public function emit(x:Float, y:Float)
	{
		var particle = this.get();
		activeMembers.add(particle);
		particle.reset(x, y);
		particle.revive();
		return particle;
	}

	public static function burstEmit(color:FlxColor, ?radiiMax:Float = 600, ?overwriteProps:ParticleProps = null):ParticleProps
	{
		var initVel = FlxPoint.get(FlxG.random.float(-1, 1), FlxG.random.float(-1, 1)).normalize() * FlxG.random.float(0.5, 1) * radiiMax;
		var props:ParticleProps = {
			lifespan: () -> FlxG.random.float(1, 1.5),
			velocityExtended: () -> [
				{
					t: 0,
					value: initVel
				},
				{
					t: 1,
					value: initVel.clone() * 0.1
				}
			],
			scaleExtended: () -> [
				{
					t: 0,
					value: FlxPoint.get(1, 1)
				},
				{
					t: 1,
					value: FlxPoint.get(0.25, 0.25)
				}
			],
			colourExtended: () -> [
				{
					t: 0,
					value: color
				},
				{
					t: 1,
					value: color.getDarkened(0.6)
				}
			],
			alphaExtended: () -> [
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
			],
		};

		if (overwriteProps != null)
		{
			props = joinProps(props, overwriteProps);
		}

		return props;
	}

	static function joinProps(props:ParticleProps, overrideProps:ParticleProps):ParticleProps
	{
		if (overrideProps.accelerationExtended != null)
		{
			props.accelerationExtended = overrideProps.accelerationExtended;
		}
		if (overrideProps.angularVelocityExtended != null)
		{
			props.angularVelocityExtended = overrideProps.angularVelocityExtended;
		}
		if (overrideProps.velocityExtended != null)
		{
			props.velocityExtended = overrideProps.velocityExtended;
		}
		if (overrideProps.scaleExtended != null)
		{
			props.scaleExtended = overrideProps.scaleExtended;
		}
		if (overrideProps.colourExtended != null)
		{
			props.colourExtended = overrideProps.colourExtended;
		}
		if (overrideProps.alphaExtended != null)
		{
			props.alphaExtended = overrideProps.alphaExtended;
		}
		if (overrideProps.lifespan != null)
		{
			props.lifespan = overrideProps.lifespan;
		}

		return props;
	}
}

class CsParticle extends FlxParticle
{
	public var onComplete:(particle:CsParticle) -> Void;
	public var customUpdate:(particle:CsParticle) -> Void;

	public var accelerationExtended:Array<ExtendedLerpStop<FlxPoint>> = null;
	public var alphaExtended:Array<ExtendedLerpStop<Float>> = null;
	public var angularVelocityExtended:Array<ExtendedLerpStop<Float>> = null;
	public var colourExtended:Array<ExtendedLerpStop<FlxColor>> = null;
	public var velocityExtended:Array<ExtendedLerpStop<FlxPoint>> = null;
	public var scaleExtended:Array<ExtendedLerpStop<FlxPoint>> = null;
	public var target:TargetProps;

	private var effectStates:Array<ParticleProps> = [];
	private var currentEffectState:Int = 0;

	public function new()
	{
		super();
		makeGraphic(10, 10, 0xFFFFFFFF);
		kill();
	}

	public function setEffectStates(es:Array<ParticleProps>)
	{
		effectStates = es;
		currentEffectState = 0;

		if (effectStates.length == 0)
			throw "No effect states provided";

		var thisState = effectStates[currentEffectState];
		assignOverrides(thisState);
	}

	override public function update(elapsed:Float)
	{
		if (age + elapsed >= lifespan && lifespan != 0)
		{
			currentEffectState++;
			if (currentEffectState < effectStates.length)
			{
				resetProps();
				assignOverrides(effectStates[currentEffectState]);
				age = 0;
			}
			else
			{
				if (onComplete != null)
				{
					onComplete(this);
				}
			}
		}

		super.update(elapsed);

		if (alphaExtended != null)
		{
			this.alpha = ExtendedLerp.flerp(alphaExtended, age / lifespan);
		}
		if (scaleExtended != null)
		{
			this.scale = ExtendedLerp.fPlerp(scaleExtended, age / lifespan, this.scale);
		}

		if (accelerationExtended != null)
		{
			this.acceleration = ExtendedLerp.fPlerp(accelerationExtended, percent);
		}
		if (angularVelocityExtended != null)
		{
			this.angularVelocity = ExtendedLerp.flerp(angularVelocityExtended, percent);
		}
		if (colourExtended != null)
		{
			this.color = ExtendedLerp.clerp(colourExtended, percent);
		}
		if (velocityExtended != null)
		{
			this.velocity = ExtendedLerp.fPlerp(velocityExtended, percent);
		}

		if (target != null)
		{
			var easeName = "linear";

			if (target.easeName != null)
			{
				easeName = target.easeName;
			}

			var easeed = getEase(easeName, percent);

			x = FlxMath.lerp(target.origin.x, target.target.x, easeed);
			y = FlxMath.lerp(target.origin.y, target.target.y, easeed);
		}

		if (customUpdate != null)
		{
			customUpdate(this);
		}
	}

	private function assignOverrides(props:ParticleProps)
	{
		if (props.accelerationExtended != null)
		{
			accelerationExtended = props.accelerationExtended();
		}
		if (props.angularVelocityExtended != null)
		{
			angularVelocityExtended = props.angularVelocityExtended();
		}
		if (props.velocityExtended != null)
		{
			velocityExtended = props.velocityExtended();
		}
		if (props.scaleExtended != null)
		{
			scaleExtended = props.scaleExtended();
		}
		if (props.colourExtended != null)
		{
			colourExtended = props.colourExtended();
		}
		if (props.alphaExtended != null)
		{
			alphaExtended = props.alphaExtended();
		}
		if (props.lifespan != null)
		{
			lifespan = props.lifespan();
		}
		if (props.customUpdate != null)
		{
			customUpdate = props.customUpdate;
		}
		if (props.onComplete != null)
		{
			onComplete = props.onComplete;
		}
		if (props.target != null)
		{
			target = props.target(this);
		}
	}

	override function reset(X:Float, Y:Float)
	{
		super.reset(X, Y);
		resetProps();
	}

	function resetProps()
	{
		alphaRange.active = false;
		colorRange.active = false;
		velocityRange.active = false;
		scaleRange.active = false;
		angularVelocityRange.active = false;

		lifespan = 1;

		alphaExtended = null;
		colourExtended = null;
		velocityExtended = null;
		scaleExtended = null;
		angularVelocityExtended = null;
		target = null;
	}

	function getEase(ease:String, t:Float):Float
	{
		return switch (ease)
		{
			case "backIn":
				return FlxEase.backIn(t);
			case "backInOut":
				return FlxEase.backInOut(t);
			case "backOut":
				return FlxEase.backOut(t);
			case "bounceIn":
				return FlxEase.bounceIn(t);
			case "bounceInOut":
				return FlxEase.bounceInOut(t);
			case "bounceOut":
				return FlxEase.bounceOut(t);
			case "circIn":
				return FlxEase.circIn(t);
			case "circInOut":
				return FlxEase.circInOut(t);
			case "circOut":
				return FlxEase.circOut(t);
			case "cubeIn":
				return FlxEase.cubeIn(t);
			case "cubeInOut":
				return FlxEase.cubeInOut(t);
			case "cubeOut":
				return FlxEase.cubeOut(t);
			case "elasticIn":
				return FlxEase.elasticIn(t);
			case "elasticInOut":
				return FlxEase.elasticInOut(t);
			case "elasticOut":
				return FlxEase.elasticOut(t);
			case "expoIn":
				return FlxEase.expoIn(t);
			case "expoInOut":
				return FlxEase.expoInOut(t);
			case "expoOut":
				return FlxEase.expoOut(t);
			case "quadIn":
				return FlxEase.quadIn(t);
			case "quadInOut":
				return FlxEase.quadInOut(t);
			case "quadOut":
				return FlxEase.quadOut(t);
			case "quartIn":
				return FlxEase.quartIn(t);
			case "quartInOut":
				return FlxEase.quartInOut(t);
			case "quartOut":
				return FlxEase.quartOut(t);
			case "quintIn":
				return FlxEase.quintIn(t);
			case "quintInOut":
				return FlxEase.quintInOut(t);
			case "quintOut":
				return FlxEase.quintOut(t);
			case "sineIn":
				return FlxEase.sineIn(t);
			case "sineInOut":
				return FlxEase.sineInOut(t);
			case "sineOut":
				return FlxEase.sineOut(t);
			case "smoothStepIn":
				return FlxEase.smoothStepIn(t);
			case "smoothStepInOut":
				return FlxEase.smoothStepInOut(t);
			case "smoothStepOut":
				return FlxEase.smoothStepOut(t);
			case "smootherStepIn":
				return FlxEase.smootherStepIn(t);
			case "smootherStepInOut":
				return FlxEase.smootherStepInOut(t);
			case "smootherStepOut":
				return FlxEase.smootherStepOut(t);
			default:
				return FlxEase.linear(t);
		}
	}
}
