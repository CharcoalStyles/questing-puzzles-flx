package entities;

import entities.Character;
import entities.Gem;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxPool;
import utils.Observer;

class Sidebar extends FlxGroup
{
	var allStores:Map<ManaType, {bar:FlxBar, label:FlxText, particles:FlxPool<Mparticle>}>;
	var isLeft:Bool;
	var character:Character;
	var spellUis:Array<SpellUi>;

	public function new(char:Character, isLeft:Bool)
	{
		super();
		this.isLeft = isLeft;
		this.character = char;

		spellUis = [];

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

		allStores = new Map();

		var i = 0;

		var baseX = isLeft ? 0 : FlxG.width - width;

		for (gt in GemType.ALL)
		{
			var label:FlxText = new FlxText(baseX, workingY, 16, gt.shortName);
			label.setFormat(null, 12, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			label.borderSize = 2;
			add(label);

			var bar:FlxBar = new FlxBar(baseX + 24, workingY, FlxBarFillDirection.LEFT_TO_RIGHT, 100, Std.int(label.height));
			bar.createFilledBar(0xff202020, gt.color, true, gt.color);
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

			allStores.set(gt.manaType, {bar: bar, label: label, particles: em});

			workingY += Math.ceil(bar.height + paddingY);

			i++;
		}

		var hr:FlxSprite = new FlxSprite(baseX, workingY, null);
		hr.makeGraphic(width, 2, 0xff000000);
		add(hr);

		workingY += 10;

		for (spell in character.spells)
		{
			var spellUi = new SpellUi(baseX, workingY, width, spell);
			spellUis.push(spellUi);
			add(spellUi);

			for (mt in spell.manaCosts.keys())
			{
				var playerMana = character.mana[mt];
				if (playerMana != null)
				{
					playerMana.addObserver(new CallbackObserver<Float>((sender, ?data) ->
					{
						var store = allStores[mt];
						var bar = store.bar;

						trace("manaType: " + mt + " mana: " + data);
						bar.value = data;
						store.label.text = Std.string(Math.floor(bar.value)) + "/100";
						spellUi.onManaUpdate(data, mt);
					}));
				}
			}

			workingY += 60;
		}
	}

	public function addMana(mt:ManaType, amount:Int, origin:FlxPoint)
	{
		var store = allStores[mt];
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
				character.mana[mt].addA(amount / subParts);
			});
		}
	}

	public function handleClick(point:FlxPoint)
	{
		var spell:Null<Spell> = null;
		for (spellUi in spellUis)
		{
			spell = spellUi.overlaps(point);
			if (spell != null)
				break;
		}
		return spell;
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

class SpellUi extends FlxGroup
{
	var border:FlxSprite;
	var manaText:Map<ManaType, FlxText>;
	var manaChecks:Map<ManaType, Bool>;
	var spell:Spell;
	var isActivated:Bool = false;

	public function new(X:Int, Y:Int, width:Int, spell:Spell)
	{
		super();

		this.spell = spell;

		var workingY = Y;

		manaText = new Map();
		manaChecks = new Map();

		border = new FlxSprite(X, Y, null);
		border.makeGraphic(width, 50, 0xffffffff);
		border.color = 0xff000000;
		add(border);

		var bkgrnd:FlxSprite = new FlxSprite(X + 2, Y + 2, null);
		bkgrnd.makeGraphic(width - 4, 46, 0xff202020);
		add(bkgrnd);

		var name:FlxText = new FlxText(X + 5, workingY + 5, width - 10, spell.name);
		name.setFormat(null, 12, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		name.borderSize = 2;
		add(name);

		workingY += 7;
		var workingX = X + 2;
		for (type in spell.manaCosts.keys())
		{
			var gt = GemType.fromManaType(type);
			var cost = spell.manaCosts.get(type);
			var amount:Float = cost.get();
			if (amount == null || amount == 0)
				continue;
			var mc:FlxText = new FlxText(workingX + 5, workingY + 20);
			mc.text = gt.name + " (" + amount + ")";
			mc.setFormat(null, 12, gt.color, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.WHITE);
			mc.borderSize = 1;
			add(mc);
			manaText.set(type, mc);
			manaChecks.set(type, false);
			workingX += Std.int(mc.width + 5);
		}
	}

	public function overlaps(point:FlxPoint):Null<Spell>
	{
		return border.overlapsPoint(point) ? spell : null;
	}

	public function onManaUpdate(totalNumber:Float, manaType:ManaType)
	{
		var cost = spell.manaCosts.get(manaType).get();
		var check = manaChecks.get(manaType);
		var mc = manaText.get(manaType);
		if (cost != null)
			if (totalNumber >= cost && !check)
			{
				mc.color = 0xff00ff00;
				manaChecks.set(manaType, true);
			}
			else if (totalNumber < cost && check)
			{
				mc.color = 0xffff0000;
				manaChecks.set(manaType, false);
			}
	}
}
