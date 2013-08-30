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
  import flash.net.Socket;
  import flash.events.ProgressEvent;
  /**
   * This class handles the initial communication with the server before the
   * tests. It has an event handler function that call functions to handle the
   * different stages of communication with the server.
   */
  public class Handshake {
    // constants used within the class
    private const KICK_CLIENTS:int = 0;
    private const SRV_QUEUE:int = 1;
    private const VERIFY_VERSION:int = 2;
    private const VERIFY_SUITE:int = 3;
    
    // variables declaration section
    private var ctlSocket:Socket;
    private var protocolObj:Protocol;
    private var msg:Message;
    private var _yTests:int;
    private var callerObj:MainFrame;
    private var comStage:int; // variable representing the stage of communication
                              // with the server.
    private var i:int, wait:int;
    private var iServerWaitFlag:int; // flag indicating whether wait message
                                     // was already received once
    
    // event handler functions
    public function onResponse(e:ProgressEvent):void {  
      switch (comStage) {
        case KICK_CLIENTS:    kickOldClients();
                              break;
        case SRV_QUEUE:       srvQueue();
                              break;
        case VERIFY_VERSION:  verifyVersion();
                              break;
        case VERIFY_SUITE:    verifySuite();
                              break;
      }
      if (TestResults.get_bFailed()) {
        removeResponseListener();
        callerObj.finishedAll();
      }
    }
    
    private function addResponseListener():void {
      ctlSocket.addEventListener(ProgressEvent.SOCKET_DATA, onResponse);
    }
    
    private function removeResponseListener():void {
      ctlSocket.removeEventListener(ProgressEvent.SOCKET_DATA, onResponse);
    }
    
    /**
     * Function that reads and processes the message from the server to kick
     * old and unsupported clients. 
     */
    public function kickOldClients():void {
      // read the message that kicks old clients
      if (protocolObj.readn(msg, 13) != 13) {
        trace(NDTConstants.RMANAGER.getString(NDTConstants.BUNDLE_NAME, 
                                              "unsupportedClient", null,
                                              Main.locale));
        TestResults.appendErrMsg(
          NDTConstants.RMANAGER.getString(NDTConstants.BUNDLE_NAME,
                                          "unsupportedClient",
                                          null, Main.locale) + "\n");
        TestResults.set_bFailed(true);
        return;
      }      
      comStage = SRV_QUEUE;
      if (ctlSocket.bytesAvailable > 0) {
        srvQueue();
      }
    }
    
    /**
     * Function that handles the queue responses from the server. The onResponse
     * function will continue to loop here until comStage is changed to indicate
     * that the waiting period is over.
     */
    public function srvQueue():void {
      // If SRV_QUEUE message sent by the server does not indicate
      // that the test session starts now, return
      if (protocolObj.recv_msg(msg) != NDTConstants.SRV_QUEUE_TEST_STARTS_NOW) {
        TestResults.appendErrMsg(
          NDTConstants.RMANAGER.getString(NDTConstants.BUNDLE_NAME, 
                                          "protocolError", null, Main.locale) 
          + parseInt(new String(msg.getBody()), 16) + " instead\n");
        TestResults.set_bFailed(true);
        return;
      }
      // If message is not of SRV_QUEUE type, it is incorrect at this stage.
      if (msg.getType() != MessageType.SRV_QUEUE) {
        TestResults.appendErrMsg(
          NDTConstants.RMANAGER.getString(NDTConstants.BUNDLE_NAME,
                                          "loggingWrongMessage",
                                          null, Main.locale) + "\n");
        TestResults.set_bFailed(true);
        return;
      }
      
      // Handling different queued-client cases below
      // Get wait flag value
      var tmpstr:String = new String(msg.getBody());
      wait = parseInt(tmpstr);
      trace("Wait flag received = " + String(wait));
      TestResults.appendTraceOutput("Wait flag received = " 
                                    + String(wait) + "\n");
      if (wait == 0) {
        // SRV_QUEUE message indicates tests should start,
        // so proceed to next stage.
        trace("Finished waiting");
        TestResults.appendTraceOutput("Finished waiting" + "\n");
        comStage = VERIFY_VERSION;
        if(ctlSocket.bytesAvailable > 0) {
          verifyVersion();
          return;
        }
        return;
      }
      if (wait == NDTConstants.SRV_QUEUE_SERVER_BUSY) {
        if (iServerWaitFlag == 0) {
          // Message indicating server is busy,
          TestResults.appendErrMsg(
            NDTConstants.RMANAGER.getString(NDTConstants.BUNDLE_NAME, 
                                            "serverBusy",null, Main.locale) + "\n");
          TestResults.set_bFailed(true);
          return;
        } else {
          // Server fault, return
          TestResults.appendErrMsg(
            NDTConstants.RMANAGER.getString(NDTConstants.BUNDLE_NAME,
                                            "serverFault", null, Main.locale) + "\n");
          TestResults.set_bFailed(true);
          return;
        }
      }
      // server busy for 60s, wait for previous test to finish
      if (wait == NDTConstants.SRV_QUEUE_SERVER_BUSY_60s) {
        TestResults.appendErrMsg(
          NDTConstants.RMANAGER.getString(NDTConstants.BUNDLE_NAME,
                                          "serverBusy60s", null, Main.locale) + "\n");
        TestResults.set_bFailed(true);
        return;
      }
      // server sends signal to see if client is still alive
      // client should respond with a MSG_WAITING message
      if (wait == NDTConstants.SRV_QUEUE_HEARTBEAT) {
        protocolObj.send_msg(MessageType.MSG_WAITING, _yTests);
        return;
      }
      
      // Each test should take less than 30s, so tell them 45 sec * number of
      // test suites waiting in the queue. Server sends a number equal to number
      // of queued clients == number of minutes to wait before starting tests.
      // wait = minutes to wait = number of queued clients.
      wait = (wait * 45);
      TestResults.appendConsoleOutput(
        NDTConstants.RMANAGER.getString(NDTConstants.BUNDLE_NAME,
                                        "otherClient", null, Main.locale) + wait
        + NDTConstants.RMANAGER.getString(NDTConstants.BUNDLE_NAME,
                                          "seconds", null, Main.locale) + ".\n");
      iServerWaitFlag = 1;  // first message from server now already encountered
    }
    
    /**
     * Function that verifies version compatibility between the server
     * and the client. 
     */
    public function verifyVersion():void {
      // The server must send a message to verify version,
      // and this is a MSG_LOGIN type message.
      if (protocolObj.recv_msg(msg) != NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
        // there is a protocol error so return
        TestResults.appendErrMsg(
          NDTConstants.RMANAGER.getString(NDTConstants.BUNDLE_NAME,
                                          "protocolError", null, Main.locale)
          + parseInt(new String(msg.getBody()), 16) + " instead\n");
        TestResults.set_bFailed(true);
        return;
      }
      if (msg.getType() != MessageType.MSG_LOGIN) {
        // only this type of message should be received at this stage.
        // every other message is wrong.
        TestResults.appendErrMsg(
          NDTConstants.RMANAGER.getString(NDTConstants.BUNDLE_NAME,
                                          "versionWrongMessage", 
                                          null, Main.locale) + "\n");
        TestResults.set_bFailed(true);
        return;
      }
      // version compatibility between server and client must be verified.
      var vVersion:String = new String(msg.getBody());
      if (!(vVersion.indexOf("v") == 0)) {
        TestResults.appendErrMsg(
          NDTConstants.RMANAGER.getString(NDTConstants.BUNDLE_NAME,
                                          "incompatibleVersion",
                                          null, Main.locale) + "\n");
        TestResults.set_bFailed(true);
        return;
      }
      trace("Server version : " + vVersion.substring(1));
      TestResults.appendTraceOutput("Server Version : "
                                    + vVersion.substring(1) + "\n");
      comStage = VERIFY_SUITE;
      if (ctlSocket.bytesAvailable > 0) {
        verifySuite();
      }
    }
    
    /**
     * Function that verifies that the suite previously requested by the client
     * is the same as the one the server has sent. If successfully completed,
     * the function calls allComplete that initiates the tests requested in the
     * test suite.
     */
    public function verifySuite():void {
      // Read server message again. Server must send a MSG_LOGIN message to
      // negotiate the test suite and this should be the same set of tests
      // requested by the client earlier.
      if (protocolObj.recv_msg(msg) != NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
        TestResults.appendErrMsg(
          NDTConstants.RMANAGER.getString(NDTConstants.BUNDLE_NAME,
                                          "protocolError", null, Main.locale)
          + parseInt(new String(msg.getBody()), 16) + " instead\n");
        TestResults.set_bFailed(true);
        return;
      }
      if (msg.getType() != MessageType.MSG_LOGIN) {
        // only tests negotiation message expected at this point.
        // any other type is wrong.
        TestResults.appendErrMsg(
          NDTConstants.RMANAGER.getString(NDTConstants.BUNDLE_NAME,
                                          "testsuiteWrongMessage",
                                          null, Main.locale) + "\n");
        TestResults.set_bFailed(true);
        return;
      }
      allComplete();
    }
    
    /**
     * Function that removes the local event handler for the Control Socket
     * responses and passes control back to the caller object. 
     */
    public function allComplete():void {
      removeResponseListener();
      callerObj.initiateTests(protocolObj, msg);
    }
    
    /**
     * Constructor for the class. Initializes local variables to the ones
     * obtained from MainFrame. Starts the handshake process by sending a
     * MSG_LOGIN type message to the server.
     * @param {Socket} socket The object used for communication
     * @param {Protocol} proOb The Protocol object of ctlSocket
     * @param {Message} messg A Message object used to receive messages
     * @param {int} testPack The requested test-suite
     * @param {MainFrame} callerObject Reference to the caller object instance.
     */
    public function Handshake(socket:Socket, proOb:Protocol, messg:Message,
                              testPack:int, callerObject:MainFrame) {
      ctlSocket = socket;
      protocolObj = proOb;
      msg = messg;
      _yTests =  testPack;
      callerObj = callerObject;
      
      // initializing local variables
      iServerWaitFlag = 0;
      wait = 0;
      i = 0;
      comStage = KICK_CLIENTS;
      TestResults.set_bFailed(false);
      addResponseListener();
      
      // The beginning of the protocol
      // write out test suite request by sending a login message
      // _yTests indicates the requested test-suite
      protocolObj.send_msg(MessageType.MSG_LOGIN, _yTests);      
    }
  }
}
