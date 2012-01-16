/* socketpolicyd: a socket policy server

howto build:
-----------
generate socketpolicyd.abc

go to the root of the project
$ cd socketpolicyd

then generate a swf file that combine avmglue.abc and socketpolicyd.abc
$ ./bin/swfmake -c -o policy.swf bin/avmglue.abc src/socketpolicyd.abc

and then build an executable
$ ./bin/createprojector -exe ./bin/redshell_d -o socketpolicyd policy.swf

just display the help
$ ./socketpolicyd -h
*/

include "spitfire/SocketPolicyServer.as"

//main entry point
import avmplus.System;
import spitfire.SocketPolicyServer;

var help:String = <![CDATA[
Simple socket policy file server for Flash

Usage:
socketpolicyd [-h] [-v] [-a <address>] [-p <port>] [-f <filename>]

-h             display this help

-v             verbose output
	
-a address     IP address to bind to (default is `127.0.0.1`)

-p port        port to bind to (default is `843`)

-f filename    path of the policy file (default is `flashpolicy.xml`)

Examples:
$ ./socketpolicyd -f policy.xml
]]>;


var i:uint = 0;
var argc:uint  = System.argv.length;
var argv:Array = System.argv;
var s:String;

var address:String  = "0.0.0.0";
var port:uint       = 843;
var file:String     = "flashpolicy.xml";
var verbose:Boolean = false;

while( i < argc )
{
	s = argv[i];
	
	if( s == "-h" )
	{
		trace( help );
		System.exit(0);
	}
	else if( s == "-a" )
	{
		address = String( argv[i+1] );
		i += 2;
	}
	else if( s == "-p" )
	{
		port = parseInt( argv[i+1] );
		i += 2;
	}
	else if( s == "-f" )
	{
		file = String( argv[i+1] );
		i += 2;
	}
	else if( s == "-v" )
	{
		verbose = true;
		i++;
	}
	else if( s.charAt(0) == "-" )
	{
		trace( "invalid option" );
		trace( help );
		System.exit(1);
	}
}


var server:SocketPolicyServer = new SocketPolicyServer( address, port, file, verbose );
server.start();
