package spitfire
{
	import C.string.strerror;
	import C.unistd.sleep;
	
	import avmplus.FileSystem;
	import avmplus.Socket;
	import avmplus.System;
	
	public class SocketPolicyServer
	{
		private var _connections:Array;
		
		private var _socket:Socket;
		
		private var _address:String;
		private var _port:uint;
		private var _file:String;
		private var _policy:String;
		
		private var _verbose:Boolean;
		private var _running:Boolean;
		
		private var _refresh:uint = 1000; //ms
		
		public function SocketPolicyServer( address:String = "127.0.0.1",
											port:uint = 843,
											file:String = "flashpolicy.xml",
											verbose:Boolean = false )
		{
			_connections = [];
			
			_address = address
			_port    = port;
			_file    = file;
			_verbose = verbose;
			_running = false;
			
			if( !_verbose ) { Socket.prototype.record = function() {}; }
			_socket  = new Socket();
			_socket.reuseAddress = true;
			_connections.push( _socket );
		}
		
		private function _start():void
		{
			onStart();
			
			while( _running )
			{
				_loop();
				sleep( _refresh );
			}
			
			_stop();
		}
		
		private function _stop():void
		{
			_allConn( "close" );
			_socket.close();
			onStop();
		}
		
		private function _allConn( call:String ):void
		{
			var i:uint;
			var len:uint = _connections.length;
			var current:Socket;
			
			for( i=0; i<len; i++ )
			{
				current = _connections[i];
				
				if( current != _socket )
				{
					current[ call ]();
				}
			}
		}
		
		private function _loop():void
		{
			var i:uint;
			var len:uint = _connections.length;
			var selected:Socket;
			var newconn:Socket;
			
			var data:String;
			
			for( i=0; i<len; i++ )
			{
				if( _verbose ) { trace( "selected connection ["+i+"]" ); }
				selected = _connections[i];
				
				if( selected && selected.valid && selected.readable )
				{
					if( _verbose ) { trace( "we can read on ["+i+"]" ); }
					
					if( selected == _socket ) //new connection / read data on server
					{
						if( _verbose ) { trace( "read data on server" ); }
						newconn = _socket.accept();
						if( _verbose ) { trace( "accepted new connection" ); }
						
						if( !newconn.valid )
						{
							//error
							//TODO
							trace( "Error accepting connection: " + Socket.lastError );
							if( _verbose ) { trace( strerror( Socket.lastError ) ); }
						}
						else
						{
							_connections.push( newconn );
						}
						
					}
					else //read data from clients
					{
						if( _verbose ) { trace( "read data from clients" ); }
						
						try
						{
							data = selected.receiveAll( 1024 );
						}
						catch( e:Error )
						{
							//error receiving data from client
							trace( "Error accepting connection: " + e );
						}
						
						if( !selected.valid )
						{
							//not valid client
							if( _verbose ) { trace( "not valid client" ); }
							_connections.splice( i, 1 );
						}
						else
						{
							//valid client
							_interpret( data, selected );
						}
					}                                                      
					
				} //readable
				
				//                if( selected && selected.valid && selected.writable )
				//                {
				//                    trace( "we can write" );
				//                }
				
			} //for loop
		}
		
		private function _verifyAndLoadFile( file:String ):Boolean
		{
			var absolute:String = FileSystem.absolutePath( file );
			
			if( !FileSystem.exists( absolute ) )
			{
				trace( "file \"" + file + "\" does not exists." );
				return false;
			}
			
			_policy = FileSystem.read( absolute );
			return true;
		}
		
		private function trim( source:String , chars:Array = null ):String
		{
			if( chars == null )
			{
				chars = ["\n","\r","\t"];
			}
			if ( source == null || source == "" )
			{
				return "" ;
			}
			
			var i:int , l:int ;
			
			////// start
			
			l = source.length ;
			for( i = 0; (i < l) && (chars.indexOf( source.charAt( i ) ) > - 1) ; i++ )
			{
			}
			source = source.substring( i );
			
			////// end
			
			l = source.length ;
			for( i = source.length - 1; (i >= 0) && (chars.indexOf( source.charAt( i ) ) > - 1) ; i-- )
			{
			}
			source = source.substring( 0, i + 1 ) ;
			
			////// 
			
			return source ;
		}
		
		private function _interpret( message:String, current:Socket = null ):void
		{
			message = trim( message );
			if( _verbose ) { trace( "message received = \"" + message + "\"" ); }
			
			if( message == "<policy-file-request/>" )
			{
				trace( "Valid request received from " + current.local );
				current.send( _policy );
				trace( "Sent policy file to " + current.local );
			}
			else
			{
				trace( "Unrecognized request from " + current.local + ": " + message );
			}
		}
		
		
		public function start():void
		{
			if( _verifyAndLoadFile( _file ) )
			{
				trace( "Found policy file" );
				
				if( !_socket.bind( _port, _address ) )
				{
					trace( "could not bind to port " + _port );
					trace( "on some system you need admin rights to listen on port smaller than 1024" );
					System.exit(1);
				}
				
				if( !_socket.listen( 128 ) )
				{
					trace( "could not listen" );
					System.exit(1);
				}
				
				
				_running = true;
				
				_start();
				
			}
			else
			{
				trace( "You Need to provide a valid policy file" );
				System.exit(1);
			}
		}
		
		public function stop():void
		{
			_running = false;
		}
		
		public function onStart():void
		{
			trace( "Socket Policy Server started - " + _address + ":" + _port );
		}
		
		public function onStop():void
		{
			trace( "Socket Policy Server stoped" );
		}
		
		
	}
	
}