package utils;

interface Observer<T>
{
	public function notified(sender:Observable<T>, ?data:T):Void;
}

class CallbackObserver<T> implements Observer<T>
{
	private var callback:(sender:Observable<T>, ?data:T) -> Void;

	public function new(onObservation:(sender:Observable<T>, ?data:T) -> Void)
	{
		callback = onObservation;
	}

	public function notified(sender:Observable<T>, ?data:T):Void
	{
		callback(sender, data);
	}
}

class Observable<T>
{
	private var observers:Array<Observer<T>> = [];

	public function new() {}

	private function notify(?data:T)
	{
		for (obs in observers)
			obs.notified(this, data);
	}

	public function addObserver(observer:Observer<T>)
	{
		observers.push(observer);
	}

	public function removeObserver(observer:Observer<T>)
	{
		var index = observers.indexOf(observer);
		if (index != -1)
			observers.splice(index, 1);
	}

	public function clearObservers()
	{
		for (obs in observers)
			removeObserver(obs);
	}
}

class IntObservableActual extends Observable<Int>
{
	public var value(default, set):Int;

	function set_value(value:Int):Int
	{
		this.value = value;
		notify(this.value);
		return this.value;
	}

	public function new(value:Int)
	{
		super();
		this.value = value;
	}
}

class FloatObservableActual extends Observable<Float>
{
	public var value(default, set):Float;

	function set_value(value:Float):Float
	{
		this.value = value;
		notify(this.value);
		return this.value;
	}

	public function new(value:Float)
	{
		super();
		this.value = value;
	}
}

abstract IntObservable(IntObservableActual)
{
	public inline function new(value:Int)
	{
		this = new IntObservableActual(value);
	}

	public function addObserver(observer:Observer<Int>)
	{
		this.addObserver(observer);
		observer.notified(this, this.value);
	}

	public function removeObserver(observer:Observer<Int>)
	{
		this.removeObserver(observer);
	}

	public function clearObservers()
	{
		this.clearObservers();
	}

	public function set(value:Int):Int
	{
		return this.value = value;
	}

	@:op(A + B)
	public function add(value:Int)
	{
		return this.value + value;
	}

	@:op(A += B)
	public function addA(value:Int)
	{
		return this.value = add(value);
	}

	@:op(A - B)
	public function sub(value:Int)
	{
		return this.value - value;
	}

	@:op(A -= B)
	public function subA(value:Int)
	{
		return this.value = sub(value);
	}

	@:op(A * B)
	public function mul(value:Int)
	{
		return this.value * value;
	}

	@:op(A *= B)
	public function mulA(value:Int)
	{
		return this.value = mul(value);
	}

	@:op(A * B)
	public function mulF(value:Float)
	{
		return Std.int(this.value * value);
	}

	@:op(A *= B)
	public function mulAF(value:Float)
	{
		return this.value = mulF(value);
	}

	@:op(A / B)
	public function div(value:Int)
	{
		return Std.int(this.value / value);
	}

	@:op(A /= B)
	public function divA(value:Int)
	{
		return this.value = div(value);
	}

	@:op(A / B)
	public function divAF(value:Float)
	{
		return Std.int(this.value / value);
	}

	@:op(A < B)
	public function less(value:Int)
	{
		return this.value < value;
	}

	@:op(A <= B)
	public function lessEq(value:Int)
	{
		return this.value <= value;
	}

	@:op(A > B)
	public function greater(value:Int)
	{
		return this.value > value;
	}

	@:op(A >= B)
	public function greaterEq(value:Int)
	{
		return this.value >= value;
	}
}

abstract FloatObservable(FloatObservableActual)
{
	public inline function new(value:Float)
	{
		this = new FloatObservableActual(value);
	}

	public inline function get():Float
	{
		return this.value;
	}

	public function addObserver(observer:Observer<Float>)
	{
		this.addObserver(observer);
		observer.notified(this, this.value);
	}

	public function removeObserver(observer:Observer<Float>)
	{
		this.removeObserver(observer);
	}

	public function clearObservers()
	{
		this.clearObservers();
	}

	public function set(value:Float)
	{
		return this.value = value;
	}

	@:op(A + B)
	public function add(value:Float)
	{
		return this.value + value;
	}

	@:op(A += B)
	public function addA(value:Float)
	{
		return this.value = add(value);
	}

	@:op(A - B)
	public function sub(value:Float)
	{
		return this.value - value;
	}

	@:op(A -= B)
	public function subA(value:Float)
	{
		return this.value = sub(value);
	}

	@:op(A * B)
	public function mul(value:Float)
	{
		return this.value * value;
	}

	@:op(A *= B)
	public function mulA(value:Float)
	{
		return this.value = mul(value);
	}

	@:op(A / B)
	public function div(value:Float)
	{
		return this.value / value;
	}

	@:op(A /= B)
	public function divA(value:Float)
	{
		return this.value = div(value);
	}

	@:op(A < B)
	public function less(value:Float)
	{
		return this.value < value;
	}

	@:op(A <= B)
	public function lessEq(value:Float)
	{
		return this.value <= value;
	}

	@:op(A > B)
	public function greater(value:Float)
	{
		return this.value > value;
	}

	@:op(A >= B)
	public function greaterEq(value:Float)
	{
		return this.value >= value;
	}
}
