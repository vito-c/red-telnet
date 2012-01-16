package spitfire
{
    import avmplus.Socket;
    
    import flash.utils.ByteArray;
    
    public class Client
    {
        private var _socket:Socket;
        
        public function Client( socket:Socket )
        {
            _socket = socket;
        }
        
        public function get address():String
        {
            if( _socket.local.indexOf(":") > 0 )
            {
                return _socket.local.split(":")[0];
            }
            
            return "";
        }
        
        public function get port():String
        {
            if( _socket.local.indexOf(":") > 0 )
            {
                return _socket.local.split(":")[1];
            }
            return "";
        }
        
        public function canRead():Boolean { return _socket.readable; }
        
        public function canWrite():Boolean { return _socket.writable; }
        
        public function isValid():Boolean { return _socket.valid; }
        
        public function read():String { return _socket.receiveAll(); }
		
		public function readBinary():ByteArray { return _socket.receiveBinaryAll(); }
        
        public function write( message:String ):void { _socket.send( message ); }
		
        public function writeBinary( data:ByteArray ):void { _socket.sendBinary( data ); }
        
        public function drop():void { _socket.close(); }
        
        public function toString():String { return "[Client " + address + ":" + port + "]"; }
        
		public function isAdmin():Boolean { return false; }
    }
}
