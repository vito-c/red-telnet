package spitfire
{
    import C.unistd.sleep;
    
    import avmplus.Socket;
    import avmplus.System;
    
    import com.data.StatsClass;
    
    import flash.utils.ByteArray;
    import flash.utils.getTimer;
	
    public class Server
    {
        private var _clientChannel:Array = [];
		private var _adminChannel:Array = [];
        
		private var _userList:String;
		
        private var _socket:Socket;
        private var _server:Client;
        
        private var _adminSocket:Socket;
		private var _adminServer:Admin;
        
        private var _address:String;
        private var _port:uint;
		private var _adimPort:uint;
		private var _verbose:Boolean = true;
        private var _running:Boolean;
        
        private var _refresh:uint = 1000; //ms
        private var _maxConnections:uint = 100; //max clients allowed to connect
        
		private var _serverStats:StatsClass;
		
        private var _allowConnections:Boolean;
		
		private static var STATS:uint = 100;
		private static var MSG:uint = 10;
        
        public function Server( address:String, port:uint, adminPort:uint, verbose )
        {
            _clientChannel = [];
            _serverStats = new StatsClass();
			_serverStats.totalMemory = System.totalMemory;
			_serverStats.serverUptime = 0;
			_serverStats.numberRequests = 0;
			_serverStats.peakMemory = System.totalMemory;
			_serverStats.freeMemory = System.freeMemory;
			_serverStats.privateMemory = System.privateMemory;
			_serverStats.openConnections = 0;
			
            _address = address;
            _port    = port;
			_adimPort = adminPort;
			_verbose = verbose;
            _running = false;
			
			if( _verbose )
            	trace('--Starting Server Socket');
            Socket.prototype.record = function() {};
            
            _socket  = new Socket();
            _socket.reuseAddress = true;
            _adminSocket = new Socket();
            _allowConnections = false;
        }
        
        public function get allowConnections():Boolean
        {
            return _allowConnections;
        }
        
        public function get maxConnections():uint
        {
            return _maxConnections;
        }
        
        public function get running():Boolean
        {
            return _running;
        }
        
        public function get totalClients():uint
        {
            return _clientChannel.length-1;
        }
        
        public function start():void
        {
            _socket.bind( _port, _address );
            _socket.listen( 128 );
            _adminSocket.bind( _adimPort, _address );
            _adminSocket.listen(128); //no backlog for admin
            _running = true;
            _allowConnections = true;
            
            _server = new Client( _socket );
			_adminServer = new Admin( _adminSocket );
			
            _addClient( _server );
			_addAdmin( _adminServer );
			if( _verbose )
            	trace('--Starting Server');
            _start();
        }
        
        public function stop():void
        {
            _running = false;
        }
        
        private function _start():void
        {
            onStart();
            
            while( _running )
            {
                _loop();
                sleep( _refresh );
				sendStats();
            }
            _stop();
        }
		
        public function sendStats():void
		{
			//valid client
			var binary:ByteArray;
			var alen:uint = _adminChannel.length 
			var clen:uint = _clientChannel.length;
			if( alen == 1 ) return;
			_serverStats.serverUptime = System.getTimer();
			_serverStats.numberRequests = 0;
			_serverStats.totalMemory = System.totalMemory;
			_serverStats.peakMemory = Math.max( System.totalMemory, _serverStats.peakMemory );
			_serverStats.freeMemory = System.freeMemory;
			_serverStats.privateMemory = System.privateMemory;
			_serverStats.openConnections = alen + clen;
			
			binary = new ByteArray();
			binary.writeByte( Server.STATS );
			
			binary.writeUTF('{"serverUptime":'+_serverStats.serverUptime+","+
				'"numberRequests":'+_serverStats.numberRequests+","+
				'"totalMemory":'+_serverStats.totalMemory+","+
				'"peakMemory":'+_serverStats.peakMemory+","+
				'"freeMemory":'+_serverStats.peakMemory+","+
				'"openConnections":'+_serverStats.openConnections+"}");
			_broadcast( binary, _adminChannel, _adminServer );			
		}
		
        public function onStart():void
        {
            trace( "Client Server started - " + _address + ":" + _port );
            trace( "Admin Server started - " + _adminServer.address + ":" + _adminServer.port );
        }
        
        public function onStop():void
        {
            trace( "Server stoped" );
        }
        
        private function _stop():void
        {
            _allClient( "drop" );
            
            //_socket.close();
            _server.drop();
            
            onStop();
        }
        
        private function _loop():void
        {
            var i:uint;
            var j:uint;
            var len:uint = _clientChannel.length;
            var alen:uint = _adminChannel.length;
            var selected:Client;
			var aselected:Admin;
            var newconn:Socket;
            
            var data:String;
			
			
			//Client Loop
            for( i=0; i<len; i++ ){
                selected = _clientChannel[i];
                
                if( selected.canRead() ){
					//new connection / read data on server
                    if( selected == _server ){
						_setupConnection( _socket, false );
					} else{
                        try{
                            data = selected.read();
                        } catch( e:Error ){
                            //error receiving data from client
                            _removeClient( selected );
						}
                        
                        if( !selected.isValid() ){
                            //not valid client
                            _removeClient( selected );
                        } else{
                            //valid client
                            _interpret( data, _clientChannel.concat(_adminChannel), selected );
                        }
                    }
                } //canRead
                
                if( selected.isValid() && selected.canWrite() ) {
                    if( selected == _server ) {
                        //write data to server
                        //do nothing
                    }
                    else {
                        //write data to client
                        try {
                            selected.write( "SERVER_" + getTimer() );
                        }
                        catch( e:Error ) {
                            //could not write to the client
                        }
                        
                    }
                } //canWrite
            }
			
			//Admin loop
            for( j=0; j<alen; j++ ){
				aselected = _adminChannel[j];
                
                if( aselected.canRead() ){
					//new connection / read data on server
                    if( aselected == _adminServer ){
						_setupConnection( _adminSocket, true );
					} else{
						try{
							data = aselected.read();
						} catch( e:Error ){
							//error receiving data from client
							_removeClient( aselected );
						}
						
						if( !selected.isValid() ){
							//not valid client
							_removeClient( aselected );
						} else{
							//valid client
							_interpret( data, _adminChannel, aselected );
							
						}						
                    }
                } //canRead
                
                if( aselected.isValid() && aselected.canWrite() ) {
                    if( aselected == _adminServer ) {
                        //write data to server
                        //do nothing
                    }
                    else {
                        //write data to client
                        try {
							aselected.write( "SERVER_" + getTimer() );
                        }
                        catch( e:Error ) {
                            //could not write to the client
                        }
                        
                    }
                } //canWrite
            }
            
            //admin loop
            //TODO
//			if( selected.isAdmin() ){
//				try{
//					binary = selected.readBinary();
//				} catch( e:Error ){
//					//error receiving data from client
//					_removeClient( selected );
//				}
//				
//				if( !selected.isValid() ){
//					//not valid client
//					_removeClient( selected );
//				} else{
//					//valid client
//					_serverStats.serverUptime = System.getTimer();
//					_serverStats.numberRequests = 0;
//					_serverStats.totalMemory = System.totalMemory;
//					_serverStats.peakMemory = Math.max( System.totalMemory, _serverStats.peakMemory );
//					_serverStats.freeMemory = System.freeMemory;
//					_serverStats.privateMemory = System.privateMemory;
//					_serverStats.openConnections = len;
//					binary = new ByteArray();
//					binary.writeByte( Server.STATS );
//					binary.writeObject( _serverStats );
//					selected.writeBinary( binary );
//				}						
//			}
			
          
        }
		
		private function _setupConnection( sock:Socket, isAdmin:Boolean = false ):void
		{
			if( allowConnections ){
				if( totalClients < maxConnections ){
					var newconn:Socket;
					//accept a new client connection
					if( _verbose )
						trace('--Set Up Connections');
					newconn = sock.accept(); //blocking
					
					if( !newconn.valid ){
						//error
						//TODO
					} else{
						//add client
						if( _verbose )
							trace('--Add Admin: '+isAdmin);
						
						if( !isAdmin ){
							_addClient( new Client( newconn ) );
						} else{
							_addAdmin( new Admin( newconn ) );
						}
					}
				} else{
					//max connections reached, can not accept new clients
				}
			} else{
				//connections not allowed
			}
		}
        
        private function _allClient( call:String ):void
        {
            var i:uint;
            var len:uint = _clientChannel.length;
            var current:Client;
            
            for( i=0; i<len; i++ )
            {
                current = _clientChannel[i];
                
                if( current != _server )
                {
                    current[ call ]();
                }
            }
        }
        
        private function _addClient( client:Client ):void
        {
            _clientChannel.push( client );
        }
        private function _addAdmin( admin:Admin ):void
        {
            _adminChannel.push( admin );
        }
        
        private function _removeClient( client:Client ):void
        {
            
        }
        
        private function _broadcast( payload:ByteArray, channels:Array= null, exclude:Client = null ):void
        {
            var i:uint;
            var len:uint = channels.length;
            var current:Client;
            for( i=0; i<len; i++ )
            {
                current = channels[i];
                
                if( current == exclude )
                {
                    continue;
                }
                
                if( current != _server && current != _adminServer )
                {
//					data.writeByte( cmd );
//					data.writeUTF( data );
					try{
						current.writeBinary( payload );
					} catch(e:Error){
//						_removeClient( current );	
						trace("payload error");
//						current.drop();
					}
                }
            }
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
        
        private function _interpret( message:String, channels:Array = null, current:Client = null ):void
        {
            message = trim( message );
            trace( "message = \"" + message + "\""+" num receivers: "+channels.length+" admins: "+_adminChannel.length + " clients: "+_clientChannel.length );
            
            if( message == "killall" )
            {
                stop();
            }
            else
            {
				var data:ByteArray = new ByteArray();
				data.writeByte( Server.MSG );
				data.writeUTF( message );
				_broadcast( data, channels, current );
//                _broadcast( data, channels, current );
            }
        }
        
    }
}
