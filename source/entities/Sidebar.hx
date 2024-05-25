package entities;

import entities.Character;
import entities.Gem;
import entities.effects.CsEmitter;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxPool;
import haxe.Timer;
import js.html.Console;
import utils.ExtendedLerp;
import utils.GlobalState;
import utils.Observer;
import utils.SplitText;
import utils.UiFlxGroup;

class Sidebar extends UiFlxGroup
{
	public var allStores:Map<ManaType, {bar:FlxBar, label:FlxText, colour:FlxColor}>;

	var isLeft:Bool;
	var character:Character;

	public var spellUis:Array<SpellUi>;

	var title:SplitText;

	public var healthText:FlxText;

	var globalState:GlobalState;

	public var isActive(default, set):Bool = false;

	function set_isActive(val)
	{
		if (isActive == val)
		{
			isActive = val;
			return val;
		}
		isActive = val;

		if (isActive)
		{
			animateOneShot();
		}
		else
		{
			title.stopAnimation();
		}
		return isActive;
	}

	function animateOneShot()
	{
		if (isActive)
		{
			title.animateWave(10, 0.1, 0.75, true);
			title.animateColour(0xff2e76b5, 0.1, 0.75);
			Timer.delay(animateOneShot, 2000);
		}
	}

	public function new(char:Character, isLeft:Bool)
	{
		super();

		globalState = FlxG.plugins.get(GlobalState);

		this.isLeft = isLeft;
		this.character = char;

		spellUis = [];

		var background:FlxSprite = new FlxSprite(0, 0);
		var height = Std.int(Math.min(FlxG.height, FlxG.width));
		var width = Std.int((Math.max(FlxG.height, FlxG.width) - height) / 2);
		var baseX = isLeft ? 0 : FlxG.width - width;

		background.makeGraphic(width, height, 0xff303030);
		background.x = baseX;
		background.y = 0;

		setScreenArea(new FlxRect(background.x, background.y, background.width, background.height));
		add(background);

		var padding = 4;
		var hPadding:Int = Std.int(padding / 2);
		var paddedWorkingWidth = {
			left: baseX + padding,
			right: baseX + width - padding,
			width: width - padding * 2,
			lCol: {
				left: baseX + padding,
				right: baseX + width / 2 - hPadding,
			},
			rCol: {
				left: baseX + width / 2 + hPadding,
				right: baseX + width - padding,
			}
		};

		var workingY = 0;

		workingY += 10;

		title = new SplitText(paddedWorkingWidth.left, workingY, char.name);
		title.borderColor = 0xff111111;
		title.borderQuality = 2;
		title.borderSize = 2;
		title.borderStyle = FlxTextBorderStyle.OUTLINE;
		title.x = paddedWorkingWidth.left + (paddedWorkingWidth.width - title.width) / 2;
		add(title);

		workingY += Std.int(title.height + 15);

		allStores = new Map();
		var i = 0;
		var maxMana = 0;

		for (gt in GemType.ALL)
		{
			var max = char.maxMana[gt.manaType];
			if (max > maxMana)
				maxMana = max;
		}

		for (gt in GemType.ALL)
		{
			var mtLabel:FlxText = new FlxText(paddedWorkingWidth.lCol.left, workingY, 196, gt.name);
			mtLabel.setFormat(null, 16, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			mtLabel.borderSize = 2;
			add(mtLabel);

			var amtLabel = new FlxText(paddedWorkingWidth.lCol.left, workingY, 196,
				Std.string(char.mana[gt.manaType].get()) + "/" + Std.string(char.maxMana[gt.manaType]));
			amtLabel.setFormat(null, 16, FlxColor.WHITE, FlxTextAlign.RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			amtLabel.borderSize = 2;
			add(amtLabel);

			workingY += Std.int(amtLabel.height + 2);

			// using char.maxMana[gt.manaType] and maxMana scale this so that the max mana bar is always the same size
			var barSize = Std.int((paddedWorkingWidth.lCol.right - paddedWorkingWidth.lCol.left) / maxMana * char.maxMana[gt.manaType]);

			var bar:FlxBar = new FlxBar(paddedWorkingWidth.lCol.left, workingY, FlxBarFillDirection.LEFT_TO_RIGHT, barSize, Std.int(amtLabel.height), null,
				"", 0, char.maxMana[gt.manaType], true);

			bar.createFilledBar(0xff202020, gt.colour, true, gt.colour);
			add(bar);

			allStores.set(gt.manaType, {bar: bar, label: amtLabel, colour: gt.colour});

			var playerMana = character.mana[gt.manaType];
			if (playerMana != null)
			{
				playerMana.addObserver(new CallbackObserver<Float>((sender, ?data) ->
				{
					bar.value = data;
					amtLabel.text = Std.string(Math.floor(bar.value)) + "/" + Std.string(char.maxMana[gt.manaType]);
				}));
			}

			workingY += Math.ceil(bar.height + 10);
			i++;
		}

		var hr:FlxSprite = new FlxSprite(paddedWorkingWidth.left, workingY, null);

		hr.makeGraphic(paddedWorkingWidth.width, 2, 0xff000000);
		add(hr);
		workingY += 10;
		for (spell in character.spells)
		{
			var spellUi = new SpellUi(paddedWorkingWidth.left, workingY, paddedWorkingWidth.width, spell, isLeft);
			spellUis.push(spellUi);
			add(spellUi);
			for (mt in spell.manaCosts.keys())
			{
				var playerMana = character.mana[mt];
				if (playerMana != null)
				{
					playerMana.addObserver(new CallbackObserver<Float>((sender, ?data) ->
					{
						spellUi.onManaUpdate(data, mt);
					}));
				}
			}
			workingY += 60;
		}

		workingY = Std.int(title.height + 25);

		var healthLabel:FlxText = new FlxText(paddedWorkingWidth.rCol.left, workingY, paddedWorkingWidth.width / 2, "Health");
		healthLabel.setFormat(null, 24, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		healthLabel.borderSize = 2;
		add(healthLabel);

		workingY += Std.int(healthLabel.height + 5);

		healthText = new FlxText(paddedWorkingWidth.rCol.left, workingY, paddedWorkingWidth.width / 2,
			Std.string(char.health) + "/" + Std.string(char.maxHealth));
		healthText.setFormat(null, 32, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		healthText.borderSize = 2;
		add(healthText);
		char.health.addObserver(new CallbackObserver<Int>((sender, ?data) ->
		{
			healthText.text = Std.string(data) + "/" + Std.string(char.maxHealth);
		}));
	}

	public function addMana(mt:ManaType, amount:Int, origin:FlxPoint)
	{
		var store = allStores[mt];
		var bar = store.bar;
		var colour = store.colour;
		var subParts = 1;
		var partScale = FlxPoint.get(1.5, 1.5);

		if (amount < 3)
		{
			subParts = 4;
			partScale.set(0.6, 0.6);
		}
		else if (amount < 7)
		{
			subParts = 2;
			partScale.set(0.9, 0.9);
		}

		for (i in 0...amount * subParts)
		{
			var p = globalState.emitter.emit(origin.x, origin.y);
			p.setEffectStates([
				CsEmitter.burstEmit(colour, 200, {
					lifespan: () -> FlxG.random.float(0.5, 1.0),
					alphaExtended: () -> [{t: 0, value: 1}],
					colourExtended: () -> [{t: 0, value: colour}],
					scaleExtended: () -> [
						{
							t: 0,
							value: partScale
						},
					]
				}),
				{
					lifespan: () -> FlxG.random.float(0.75, 0.5),
					target: (particle) -> {
						origin: FlxPoint.get(particle.x, particle.y),
						target: FlxPoint.get(bar.x, bar.y),
						easeName: "cubeIn"
					},
					scaleExtended: () -> [
						{t: 0, value: partScale},
						{t: 0.7, value: partScale.scaleNew(0.75)},
						{t: 1, value: partScale.scaleNew(0.5)},
					],
					onComplete: (particle) ->
					{
						character.mana[mt].addA(amount / subParts);
						if (character.mana[mt].get() > character.maxMana[mt])
							character.mana[mt].set(character.maxMana[mt]);
					}
				}
			]);
		}
	}

	var isMouseInside:Bool = false;

	public function handleHover(point:FlxPoint)
	{
		if (this.screenArea.containsPoint(point))
		{
			isMouseInside = true;
			for (spellUi in spellUis)
			{
				spellUi.handleHover(point);
			}
		}
		else
		{
			if (isMouseInside)
			{
				isMouseInside = false;
				for (spellUi in spellUis)
				{
					spellUi.handleHover(point);
				}
			}
		}
	}

	public function handleClick(point:FlxPoint)
	{
		if (isActive)
		{
			var spell:Null<Spell> = null;
			for (spellUi in spellUis)
			{
				spell = spellUi.handleClick(point);
				if (spell != null)
					break;
			}
			return spell;
		}
		return null;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.U)
		{
			title.stopAnimation();
		}
	}
}

class SpellUi extends FlxGroup
{
	public var rect(get, never):FlxRect;

	function get_rect():FlxRect
	{
		return FlxRect.get(border.x, border.y, border.width, border.height);
	}

	var border:FlxSprite;
	var manaText:Map<ManaType, FlxText>;
	var manaChecks:Map<ManaType, Bool>;

	public var spell:Spell;
	public var isActivated:Bool = false;

	var borderTween:FlxTween;
	var animTime = 0.8;
	var timer = 0.0;
	var isLeft:Bool;

	var tooltipBackground:FlxSprite;
	var tooltipText:FlxText;

	var isHovering:Bool = false;

	public function new(X:Int, Y:Int, width:Int, spell:Spell, isLeft:Bool)
	{
		super();
		this.isLeft = isLeft;

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
		name.setFormat(null, 16, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		name.borderSize = 2;
		add(name);

		workingY += 7;
		var workingX = X + 2;
		for (type in spell.manaCosts.keys())
		{
			var gt = GemType.fromManaType(type);
			var cost = spell.manaCosts.get(type);
			var amount:Float = cost.get();
			if (amount == 0)
				continue;
			var mc:FlxText = new FlxText(workingX + 5, workingY + 20);
			mc.text = gt.name + " (" + amount + ")";
			mc.setFormat(null, 16, gt.colour, FlxTextAlign.LEFT);
			add(mc);
			manaText.set(type, mc);
			manaChecks.set(type, false);
			workingX += Std.int(mc.width + 5);
		}
		borderTween = null;

		tooltipText = new FlxText(0, 0, 0, spell.description);
		tooltipText.setFormat(null, 16, FlxColor.WHITE);
		tooltipText.alpha = 0;

		tooltipBackground = new FlxSprite(0, 0, null);
		tooltipBackground.makeGraphic(Std.int(tooltipText.width + 6), Std.int(tooltipText.height + 6), 0xff000000);
		tooltipBackground.alpha = 0;

		tooltipBackground.x = isLeft ? border.x + border.width + 8 : border.x - tooltipBackground.width - 8;
		tooltipBackground.y = border.y + (border.height - tooltipBackground.height) / 2;
		tooltipText.x = tooltipBackground.x + 3;
		tooltipText.y = tooltipBackground.y + 3;

		add(tooltipBackground);
		add(tooltipText);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		timer += elapsed;
		if (timer >= animTime)
		{
			timer = 0;
			if (isActivated && borderTween == null)
			{
				borderTween = FlxTween.color(border, animTime * 2, 0xff000000, 0xffffffff, {
					type: PINGPONG,
					ease: FlxEase.cubeIn
				});
			}
		}
	}

	function overlaps(point:FlxPoint):Bool
	{
		return border.overlapsPoint(point);
	}

	public function handleHover(point:FlxPoint)
	{
		if (overlaps(point) && !isHovering)
		{
			isHovering = true;
			tooltipBackground.alpha = 1;
			tooltipText.alpha = 1;
		}
		else if (!overlaps(point) && isHovering)
		{
			isHovering = false;
			tooltipBackground.alpha = 0;
			tooltipText.alpha = 0;
		}
	}

	public function handleClick(point:FlxPoint)
	{
		return overlaps(point) ? spell : null;
	}

	public function onManaUpdate(totalNumber:Float, manaType:ManaType)
	{
		// update to do a check to see if the mana type isin the manaCosts.
		var cost = spell.manaCosts.get(manaType).get();
		var check = manaChecks.get(manaType);

		if (totalNumber >= cost && !check)
		{
			manaChecks.set(manaType, true);
		}
		else if (totalNumber < cost && check)
		{
			manaChecks.set(manaType, false);
		}

		var allTrue = true;
		for (check in manaChecks.keys())
		{
			if (!manaChecks[check])
			{
				allTrue = false;
				break;
			}
		}

		if (allTrue && !isActivated)
		{
			isActivated = true;
		}
		else if (!allTrue && isActivated)
		{
			isActivated = false;
			if (borderTween != null)
			{
				borderTween.cancel();
				borderTween = null;
			}

			border.color = 0xff000000;
		}
	}
}
