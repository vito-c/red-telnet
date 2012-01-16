package com.events
{
	import com.data.StatsDTO;
	
	import flash.events.Event;
	
	public class AdminEvents extends Event
	{
		public static const STATS_RECEIVED:String = "statsReceived";
		public var stats:Object;
		
		public function AdminEvents(type:String, stats:Object, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			this.stats = stats;
			super(type, bubbles, cancelable);
		}
		
		override public function clone():Event
		{
			return new AdminEvents( this.type, this.stats, this.bubbles, this.cancelable );
		}
	}
}