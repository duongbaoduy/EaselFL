
package display;

	import flash.events.EventDispatcher;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.display.BitmapData;
	import Control;
	import interfaces.IBitmapData;
	import interfaces.IExec;
	import interfaces.IWatchable;
	
class FrameFl implements IExec implements IWatchable {
	
	inline static var FRAME_CHANGE:String = 'frameChange';
	static private var dispatcher:EventDispatcher = new EventDispatcher();
	static private var tmpMtx:Matrix = new Matrix();
	static private var tmpRect:Rectangle = new Rectangle();
	static private var execs:Map<String,Dynamic>;

	static public function init() {
		execs = new Map<String,Dynamic>();
		execs.set('init', sInit);
		execs.set('flp', sFlip);
	}

	/**
	 * Initialize a FrameFl based on an image
	 */
	static inline function sInit(targ:FrameFl, args:Dynamic):Void {
		targ.initialize(args);
	}
	
	/**
	 * Initialize a FrameFl based on flipping another FrameFl
	 */
	static inline function sFlip(targ:FrameFl, args:Dynamic):Void {
		targ.initializeFlipFrame(args);
	}


	//-- instance
	
	public var bitmapData:BitmapData;
	public var x(default, null):Float;
	public var y(default, null):Float;
	public var width(default, null):Float;
	public var height(default, null):Float;
	public var regX(default, null):Float;
	public var regY(default, null):Float;
	
	private var _img:IBitmapData;
	private var _eventID:String;
	private var _initialized:Bool;
	
	private var _sourceFrame:FrameFl;
	private var _sourceFlipHz:Bool;
	private var _sourceFlipVt:Bool;
	
	public var isFlip(default,null):Bool;
	
	
	
	public function new(id:Int) {
		_eventID = FRAME_CHANGE + id;
		bitmapData = ImageFl.defaultData;	
	}
	
	inline public function watch(method:Dynamic->Void):Void {
		dispatcher.addEventListener(_eventID, method, false, 0, true);
	}
	
	inline public function unwatch(method:Dynamic->Void):Void {
		dispatcher.removeEventListener(_eventID, method, false);
	}
	
	private function initialize(args:Dynamic):Void {
		if(!this._initialized) {
			this.isFlip = false;
			this._initialized = true;
			this._img = Control.bitmapDatas.get(args[0]);
			this.x = args[1];
			this.y = args[2];
			this.width = args[3];
			this.height = args[4];
			this.regX = args[5];
			this.regY = args[6];
			
			if(_img.ready){
				updateBitmap();
			}else{
				bitmapData = ImageFl.defaultData;
			}
			
			this._img.watch(updateBitmap);
		}
	}
	
	/**
	 * Handle update of image on which this FrameFl is based
	 */
	function updateBitmap(?e:Event=null):Void{
		if(!_img.ready){
				//-- clear old bitmapdata
				this.bitmapData = ImageFl.defaultData;	
		}else {
			if(x==0 && y==0 && width==_img.bitmapData.width && height==_img.bitmapData.height) {
				//-- sync bitmapdata
				bitmapData = _img.bitmapData.clone();
			}else{
				var cropBmpd = new BitmapData(Std.int(width), Std.int(height), true, 0);
				tmpMtx.identity();
				tmpMtx.tx = -x;
				tmpMtx.ty = -y;
				tmpRect.width = width;
				tmpRect.height = height;
				cropBmpd.draw(_img.bitmapData, tmpMtx, null, null, tmpRect);
				bitmapData = cropBmpd;
			}				
		}	
		
		dispatcher.dispatchEvent(new Event(_eventID));
	}
	
	
	/**
	 * Watches another frame and updates it's bitmapdata by flipping
	 * another frames bitmapdata
	 */
	function initializeFlipFrame(args:Dynamic):Void{
		if(!this._initialized) {
			this.isFlip = true;
			this._initialized = true;
			
			_sourceFrame = Control.frames.get(args[0]);
			_sourceFlipHz = args[1];
			_sourceFlipVt = args[2];
			_img = _sourceFrame._img;
			
			x = _sourceFrame.x;
			y = _sourceFrame.y;
			width = _sourceFrame.width;
			height = _sourceFrame.height;
			regX = _sourceFlipHz ? width - _sourceFrame.regX : _sourceFrame.regX;
			regY = _sourceFlipVt ? height - _sourceFrame.regX : _sourceFrame.regX;
				
			
			if(_sourceFrame._img.ready) {
				updateFromSourceFrame();
			} else {
				bitmapData = ImageFl.defaultData;
			}
			
			_sourceFrame.watch(updateFromSourceFrame);
		}
	}
	
	/**
	 * Handle the update of the BitmapData of another FrameFl
	 * on which this one is based. 
	 */
	function updateFromSourceFrame(?e:Event=null):Void {
		var flipBmpd:BitmapData;
		tmpMtx.identity();
		tmpMtx.scale(_sourceFlipHz?-1:1, _sourceFlipVt?-1:1);
		tmpMtx.translate(_sourceFlipHz?width:0, _sourceFlipVt?height:0);
		flipBmpd = new BitmapData(_sourceFrame.bitmapData.width, _sourceFrame.bitmapData.height, true, 0);
		flipBmpd.draw(_sourceFrame.bitmapData, tmpMtx);
		bitmapData = flipBmpd;
		dispatcher.dispatchEvent(new Event(_eventID));
	}
	
	public function destroy() {
		if(_sourceFrame!=null) {
			_sourceFrame.unwatch(updateFromSourceFrame);
			_sourceFrame = null;
		}
		
		if(_img!=null) {
			_img.unwatch(updateBitmap);
			_img = null;
		}
		
		bitmapData = null;
	}
	
	/**
	 * Execute a method on this FrameFl object
	 * @param String key corresponding to the method
	 * @param Array arguments for the method
	 */
	inline public function exec(method:String, ?arguments:Dynamic=null):Dynamic{
		//-- currently there is nothing you can do except set the dimension
		//-- so do that instead of looking up the method and then executing
		//return this.initialize(arguments);
		return execs.get(method)( this, arguments);
	}
}
