/* Spitfire: a socket server project
*/
//
//import avmplus.OperatingSystem;
//
//trace( "Hello: "+ OperatingSystem.username);
//
include "spitfire/Client.as"
include "spitfire/Server.as"
include "spitfire/Admin.as"
include "com/data/StatsClass.as"

//main entry point
import avmplus.System;

import com.data.StatsClass;

import spitfire.Server;

var i:uint = 0;
var argc:uint  = System.argv.length;
var argv:Array = System.argv;
var address:String  = "0.0.0.0";
var port:uint       = 9980;
var adminPort:uint = 9980;
var str:String;
var verbose:Boolean = true;

var help:String = <![CDATA[
Simple socket policy file server for Flash

Usage:
socketpolicyd [-h] [-v] [-a <address>] [-p <port>] [-f <filename>]

-h             display this help

-v             verbose output
	
-a address     IP address to bind to (default is `127.0.0.1`)

-p port        port to bind to (default is `3030`)

-s admin port  port to bind admin users to (default is `3333`)

Examples:
$ ./socketpolicyd -f policy.xml
]]>;

while( i < argc )
{
	str = argv[i];
	
	if( str == "-h" )
	{
		trace( help );
		System.exit(0);
	}
	else if( str == "-a" )
	{
		address = String( argv[i+1] );
		i += 2;
	}
	else if( str == "-p" )
	{
		port = parseInt( argv[i+1] );
		i += 2;
	}
	else if( str == "-v" )
	{
		verbose = true;
		i++;
	}
	else if( str.charAt(0) == "-" )
	{
		trace( "invalid option" );
		trace( help );
		System.exit(1);
	}
}

var server:Server = new Server( address, port, adminPort, verbose );
server.start();




