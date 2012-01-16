package com.telnet
{
	import com.data.StatsDTO;
	import com.events.AdminEvents;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.Socket;
	import flash.system.Security;
	import flash.utils.ByteArray;
	
	public class Telnet extends EventDispatcher
	{
		private const CR:int = 13; // Carriage Return (CR)
		private const WILL:int = 0xFB; // 251 - WILL (option code)
		private const WONT:int = 0xFC; // 252 - WON'T (option code)
		private const DO:int   = 0xFD; // 253 - DO (option code)
		private const DONT:int = 0xFE; // 254 - DON'T (option code)
		private const IAC:int  = 0xFF; // 255 - Interpret as Command (IAC)
		
		private static var STATS:uint = 100;
		private static var MSG:uint = 10;
		private static var LOGIN:uint = 8;
		
		private var _host:String;
		private var _port:int;
		private var sock:Socket;
		private var state:int = 0;
		private var _user:String;
		private var _writing:Boolean;
		// the inner internal:
		private var __message:String = "";
		
		public function get user():String
		{
			return _user;
		}
		
		public function set user( value:String ):void
		{
			_user = value;	
		}
		
		
		
		// the public property (read-only):
		[Bindable(event='messageChanged')]
		public function get message ():String {
			return _message;
		}
		
		// the internal (read/write):
		private function get _message ():String {
			return __message;
		}
		private function set _message (value:String ):void {
			__message = value;
			
			dispatchEvent(new Event("messageChanged"));
		}	
		
		public function Telnet(host:String, port:int, user:String )
		{
			_host = host;
			_port = port;
			_user = user;
			
			sock = new Socket();
			sock.addEventListener(Event.ACTIVATE, onSocketActivate );
			sock.addEventListener(Event.CLOSE, onSocketClose);
			sock.addEventListener(Event.CONNECT, onSocketConnect);
			sock.addEventListener(Event.DEACTIVATE, onSocketDeactivate);
			
			sock.addEventListener(ProgressEvent.SOCKET_DATA, onSocketProgress);
			sock.addEventListener(IOErrorEvent.IO_ERROR, onSocketIOError);
			sock.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecError );
			

			_message += "Attempting to connect to "+host+":"+port+"\n";
			sock.connect( _host, _port );
		}
		
		public function writeStringToSocket( str:String ):void
		{
			str += "\n";
			_message += str;
			var ba:ByteArray = new ByteArray();
			ba.writeMultiByte( str, "UTF-8" );
			this.writeBytesToSocket(ba);
		}
		/**
		 * This method is called by our application and is used to send data
		 * to the server.
		 */
		public function writeBytesToSocket(ba:ByteArray):void
		{
			sock.writeBytes(ba);
			sock.flush();
		}
		
		protected function onSocketClose(event:Event):void
		{
			_message += 'Socket Event: '+event.type+" socket connected: "+sock.connected+"\n";
		}
		
		protected function onSocketConnect(event:Event):void
		{
//			_message += 'Socket Event: '+event.type+" socket connected: "+sock.connected+"\n";
			this.writeStringToSocket( "User "+_user+" has joined" );
		}
		
		protected function onSocketDeactivate(event:Event):void
		{
//			_message += 'Socket Event: '+event.type+" socket connected: "+sock.connected+"\n";
		}
		
		protected function onSocketActivate(event:Event):void
		{
//			_message += 'Socket Event: '+event.type+" socket connected: "+sock.connected+"\n";
		}
		
		protected function onSocketIOError(event:IOErrorEvent):void
		{
			_message += 'Socket IOError\n';
		}
		
		protected function onSocketProgress(event:ProgressEvent):void
		{
			var bytes:ByteArray = new ByteArray();
			sock.readBytes( bytes );
			// Loop through each available byte returned from the socket connection.
//			while ( --bytes >= 0 ){
				// Read next available byte.
			
				var json:String;
				var data:Object;
				var cmd:uint = bytes.readUnsignedByte();
				switch( cmd ){
					case Telnet.LOGIN:
						
					break;
					case Telnet.STATS:
						json = bytes.readUTF();
						data = JSON.parse( json );
						var evt:AdminEvents = new AdminEvents( AdminEvents.STATS_RECEIVED, data );
						dispatchEvent( evt );
					break;
					case Telnet.MSG:
						_message += bytes.readUTF();
					break;
				}
//			}
//			var b:int = sock.readUnsignedByte();
//				switch (state){
//					case 0:
//						// If the current byte is the "Interpret as Command" code, set the state to 1.
//						if (b == IAC){
//							state = 1;
//							// Else, if the byte is not a carriage return, display the character using the msg() method.
//						} else if (b != CR) {
//							_message += String.fromCharCode(b);
//						}
//						break;
//					case 1:
//						// If the current byte is the "DO" code, set the state to 2.
//						if (b == DO) {
//							state = 2;
//						} else {
//							state = 0;
//						}
//						break;
//					// Blindly reject the option.
//					case 2:
//						/*
//						Write the "Interpret as Command" code, "WONT" code, 
//						and current byte to the socket and send the contents 
//						to the server by calling the flush() method.
//						*/
//						sock.writeByte(IAC);
//						sock.writeByte(WONT);
//						sock.writeByte(b);
//						sock.flush();
//						state = 0;
//						break;
//				}
//			}
			_message += "\n";
			
		}
		
		public function stop():void
		{
			sock.flush();
			sock.close();
		}
		
		protected function onSecError(event:SecurityErrorEvent):void
		{
			_message += 'Socket Security Error\n';
			_message += event.text;
			sock.close();
			sock.removeEventListener(Event.ACTIVATE, onSocketActivate );
			sock.removeEventListener(Event.CLOSE, onSocketClose);
			sock.removeEventListener(Event.CONNECT, onSocketConnect);
			sock.removeEventListener(Event.DEACTIVATE, onSocketDeactivate);
			sock.removeEventListener(ProgressEvent.SOCKET_DATA, onSocketProgress);
			sock.removeEventListener(IOErrorEvent.IO_ERROR, onSocketIOError);
			sock.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecError );
			
		}
		
		protected function ioErrorHandler(event:IOErrorEvent):void
		{
			_message += 'fail\n';
			sock.close();
		}

	}
}