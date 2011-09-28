/*
 * Copyright (c) 2005, The haXe Project Contributors
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
package massive.mcover.util;

@IgnoreCover class Timer 
{
	#if (php)
	#else

	var id:Null<Int>;

	#if js
	static public var arr:Array<Timer>;
	var timerId:Int;
	#elseif neko
	var runThread:neko.vm.Thread;
	#end

	public function new(time_ms:Int)
	{
		#if flash9
			var me = this;
			id = untyped __global__["flash.utils.setInterval"](function() { me.run(); },time_ms);
		#elseif flash
			var me = this;
			id = untyped _global["setInterval"](function() { me.run(); },time_ms);
		#elseif js
			if(arr == null) arr = [];
			id = arr.length;
			arr[id] = this;
			timerId = untyped window.setInterval("massive.mcover.util.Timer.arr["+id+"].run();",time_ms);
		#elseif neko
			var me = this;
			runThread = neko.vm.Thread.create(function() { me.runLoop(time_ms); } );
		#end
	}

	public function stop()
	{
		#if( php || flash9 || flash || js )
			if (id == null) return;
		#end
		#if flash9
			untyped __global__["flash.utils.clearInterval"](id);
		#elseif flash
			untyped _global["clearInterval"](id);
		#elseif js
			untyped window.clearInterval(timerId);
			arr[id] = null;
			if (id > 100 && id == arr.length - 1) 
			{
				// compact array
				var p = id - 1;
				while ( p >= 0 && arr[p] == null) p--;
				arr = arr.slice(0, p + 1);
			}
		#elseif neko
			run = function() {};
			runThread.sendMessage("stop");
		#end
		id = null;
	}

	public dynamic function run() 
	{}

	#if neko
	function runLoop(time_ms)
	{
		var shouldStop = false;
		while( !shouldStop )
		{
			neko.Sys.sleep(time_ms/1000);
			try
			{
				run();
			}
			catch( ex:Dynamic )
			{}

			var msg = neko.vm.Thread.readMessage(false);
			if (msg == "stop") shouldStop = true;
		}
	}
	
	#end
	public static function delay(f:Void -> Void, time_ms:Int):Timer
	{
		var t = new Timer(time_ms);
		t.run = function()
		{
			t.stop();
			f();
		};
		return t;
	}
	#end

	/**
	 *	Returns a timestamp, in seconds
	 */
	public static function stamp():Float
	{
		#if flash
			return flash.Lib.getTimer() / 1000;
		#elseif neko
			return neko.Sys.time();
		#elseif php
			return php.Sys.time();
		#elseif js
			return Date.now().getTime() / 1000;
		#elseif cpp
			return untyped __time_stamp();
		#else
			return 0;
		#end
	}
}