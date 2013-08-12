﻿// Copyright 2013 M-Lab
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package  {
	
	import flash.text.TextField;
	import flash.text.*;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.net.*;
	import flash.display.DisplayObjectContainer;
	import flash.events.IOErrorEvent;
	import flash.system.Security;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import com.greensock.*;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	
	/*  
		
		This program uses the free TweenLite plugin
		from GreenSock : http://www.greensock.com/tweenlite/
	
	*/
	
	public class MainFrame extends Sprite{
		
		/*
		
			Class responsible for establishing the socket
			connection and initiating communications with the
			server (NDTP-Control).
		
			Calls functions to perform the required tests
			and to interpret the results.
		
		*/
		
		// variables declaration section
		
		private var gui:GUI;
		
		private static var sHostName:String;
		private static var clientId:String;
		private var pub_host:String;
		public var guiEnabled:Boolean;
		var ctlSocket:Socket = null;
		var tests:Array;
		var testNo:int;
		
		private var _yTests:int =  NDTConstants.TEST_C2S | NDTConstants.TEST_S2C | NDTConstants.TEST_META;
								//	NDTConstants.TEST_MID | NDTConstants.TEST_C2S 
								//  | NDTConstants.TEST_S2C | NDTConstants.TEST_SFW
								//  | NDTConstants.TEST_STATUS | NDTConstants.TEST_META;
		
		// socket event listener functions
		
		public function onConnect(e:Event):void {
			trace("Socket connected.");
			TestResults.traceOutput += "Socket connected\n";
			protocolStart();
		}
		public function onClose(e:Event):void {
			// have to check what to do
		}
		public function onError(e:IOErrorEvent):void {
			trace("IOError : " + e);
			TestResults.errMsg += "IOError : " + e;
			TestResults._bFailed = true;
			finishedAll();
		}
		public function onSecError(e:SecurityErrorEvent):void {
			trace("Security Error" + e);
			TestResults.errMsg += "Security error : " + e;
			TestResults._bFailed = true;
			finishedAll();
		}
		public function onResponse(e:ProgressEvent):void {
			// nothing as of now
		}
		
		public function addEventListeners():void {
			ctlSocket.addEventListener(Event.CONNECT, onConnect);
			ctlSocket.addEventListener(Event.CLOSE, onClose);
			ctlSocket.addEventListener(IOErrorEvent.IO_ERROR, onError);
			ctlSocket.addEventListener(ProgressEvent.SOCKET_DATA, onResponse);
			ctlSocket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecError);
		}
		
		public function removeResponseListener():void {
			ctlSocket.removeEventListener(ProgressEvent.SOCKET_DATA, onResponse);
		}
		
		public function addResponseListener():void {
			ctlSocket.addEventListener(ProgressEvent.SOCKET_DATA, onResponse);
		}
		
		// protocol functions
		
		/*
		
			Function that creates the Control Socket object
			used to communicate with the server.
			
		*/
		
		public function dottcp():void {			
			pub_host = sHostName;
			
			// default control port used for the NDT tests session. NDT server
			// listens to this port
			var ctlport:int = NDTConstants.CONTROL_PORT_DEFAULT;
			
			Security.allowDomain("*"); // not sure if necessary
			
			TestResults._bFailed = false;  // test result status is false initially
			
			TestResults.consoleOutput += DispMsgs.connectingTo + " " + 
										 sHostName + " " + DispMsgs.toRunTest
										 + "\n";
			
			ctlSocket = new Socket();
			addEventListeners();
			ctlSocket.connect(sHostName, ctlport);			
		}
		
		/*
		
			Function that creates a Handshake object to perform
			the initial pre-test handshake with the server.
			
		*/
		
		public function protocolStart():void {
			
			var protocolObj:Protocol = new Protocol(ctlSocket);
			var msg:Message = new Message();
			
			removeResponseListener();
			
			var handshake:Handshake = new Handshake(ctlSocket, protocolObj, msg, _yTests, this);
		}
		
		/*
		
			This function initializes the array 'tests' with
			the different tests received in the message from
			the server.
			
			@param protocolObj
						The Protocol object used to communicate with the server.
			
			@param msg
						A Message object that contains the test suite.
						
		*/
		
		public function initiateTests(protocolObj:Protocol, msg:Message):void {
			var tStr:String = new String(msg.getBody());
			tStr = new String(NDTUtils.trim(tStr));
			tests = tStr.split(" ");
			testNo = 0;
			
			if(guiEnabled) {
					
				// to be removed
				gui.waitMessage();
			}
			
			runTests(protocolObj);
		}
		
		/*
		
			Function that creates objects of the respective classes to run
			the tests.
			
			@param protocolObj
						The protocol object used to communicate with the server.
						
		*/
		
		public function runTests(protocolObj:Protocol):void {
			if(testNo < tests.length) {
				var test:int = parseInt(tests[testNo]);
				
				switch(test) {
					
					case NDTConstants.TEST_C2S  : var C2S:TestC2S = new TestC2S(ctlSocket, protocolObj, sHostName, this);
												  break;
					
					case NDTConstants.TEST_S2C  : var S2C:TestS2C = new TestS2C(ctlSocket, protocolObj, sHostName, this);
												  break;
												 
					case NDTConstants.TEST_META : var META:TestMETA = new TestMETA(ctlSocket, protocolObj, clientId, this);
												  break;
				}
			}
			else {
				
				// temporarily set to view results using GUI
				finishedAll();
			}
			
		}
		
		// temporary function used to view results		
		public function finishedAll():void {
			var interpRes:TestResults = new TestResults(TestS2C._sTestResults, _yTests);
			
			if(guiEnabled) {
				gui.displayResults();
			}
		}
		
		/*
		
			The constructor receives parameters from the Fla file (and thus JavaScript)
			and initializes the tool accordingly.
			
			@param stageW
						The width of the stage to which this object is added.
			
			@param stageH
						The height of the stage to which this object is added.
			
			@param Parent
						The parent Display Container object.
						
			@param hostname
						The hostname of the server passed from JavaScript.
						
			@param clientID
						The ID of this client passed from JavaScript.
						
			@param guiEnabled
						A boolean representing necessity of a Flash based GUI (true=yes, false=no).
		
		*/
		
		public function MainFrame(stageW:int, stageH:int, Parent:DisplayObjectContainer, hostname:String, cID:String, guiEnabled:Boolean) {
			// constructor code
			
			this.guiEnabled = guiEnabled;
			
			if(guiEnabled) {
				gui = new GUI(stageW, stageH, this);
				this.addChild(gui);
			}
			
			// variables initialization
			sHostName = NDTConstants.HOST_NAME; // need to check if hostname is passed and change accordingly
			clientId = cID;
			pub_host = "unknown";
		}

	}
	
}
