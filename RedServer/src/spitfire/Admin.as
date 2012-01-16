package spitfire
{
	import avmplus.Socket;
	
	public class Admin extends Client
	{
		public function Admin(socket:Socket)
		{
			super(socket);
		}
		
		override public function isAdmin():Boolean{ return true; };
		override public function toString():String{ return "[Admin " + address + ":" + port + "]"; }
	}
}