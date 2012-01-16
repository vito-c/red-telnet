package com.events
{
	import flash.events.Event;
	
	public class UserEvents extends Event
	{
		public static const USER_LOGGEDIN:String = "userLoggedIn";
		public static const USER_LOGGEDOUT:String = "userLoggedOut";
		public var user:Object;

		public function UserEvents(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}