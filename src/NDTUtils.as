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
  /**
   * Class that defines utility methods used by the NDT.
   */
  public class NDTUtils {
    /**
     * Utility method to print a double value upto 2 digits after the decimal
     * point. 
     * @param {Number} paramDblToFormat Double number to format
     * @return {String} Formatted value of the number.
     * Examples: 15.2445-->15.24  34.4-->34.4  45-->45
     */
    public static function prtdbl(paramDblToFormat:Number):String {
      var str:String = null;
      var i:int;
      
      if (paramDblToFormat == 0) {
        return("0");
      }
      
      str = paramDblToFormat.toString();
      i = str.indexOf(".");
      if (i == -1)
        return str;
      
      i += 3;
      if (i > str.length) {
        i -= 1;
      }
      if (i > str.length) {
        i -= 1;
      }
      return (str.substring(0, i));
    }
    
    /**
     * Function that trims the spaces before and after a String.
     */
    public static function trim(sParam:String):String {
      var i:int = 0;
      
      if (sParam == null)
        return null;
      
      while (sParam.charAt(i) == " ") {
        i++;
      }    
      var j:int = sParam.length - 1;
      while (sParam.charAt(j) == " ") {
        j--;
      }
      return sParam.substring(i, j+1);
    }
    
    /**
     *  Utility method to print Text values for data speed related keys.
     *  @param {int} paramIntVal Parameter for which we find text value
     *  @return {String} Textual name for input parameter
     */
    public static function prttxt(paramIntVal:int):String {
      switch (paramIntVal) {
      case NDTConstants.DATA_RATE_SYSTEM_FAULT:
        return NDTConstants.RMANAGER.getString(NDTConstants.BUNDLE_NAME,
                                               "systemFault", null, Main.locale);
      case NDTConstants.DATA_RATE_RTT:
        return NDTConstants.RMANAGER.getString(NDTConstants.BUNDLE_NAME,
                                               "rtt", null, Main.locale);
      case NDTConstants.DATA_RATE_DIAL_UP:
        return NDTConstants.RMANAGER.getString(NDTConstants.BUNDLE_NAME,
                                               "dialup2", null, Main.locale);
      case NDTConstants.DATA_RATE_T1:
        return NDTConstants.RMANAGER.getString(NDTConstants.BUNDLE_NAME,
                                               "t1Str", null, Main.locale);
      case NDTConstants.DATA_RATE_ETHERNET:
        return NDTConstants.RMANAGER.getString(NDTConstants.BUNDLE_NAME,
                                               "ethernetStr", null, Main.locale);
      case NDTConstants.DATA_RATE_T3:
        return NDTConstants.RMANAGER.getString(NDTConstants.BUNDLE_NAME,
                                               "t3Str", null, Main.locale);
      case NDTConstants.DATA_RATE_FAST_ETHERNET:
        return NDTConstants.RMANAGER.getString(NDTConstants.BUNDLE_NAME,
                                               "fastEthernet", null, Main.locale);
      case NDTConstants.DATA_RATE_OC_12:
        return NDTConstants.RMANAGER.getString(NDTConstants.BUNDLE_NAME,
                                               "oc12Str", null, Main.locale);
      case NDTConstants.DATA_RATE_GIGABIT_ETHERNET:
        return NDTConstants.RMANAGER.getString(NDTConstants.BUNDLE_NAME,
                                               "gigabitEthernetStr", 
                                               null, Main.locale); 
      case NDTConstants.DATA_RATE_OC_48:
        return NDTConstants.RMANAGER.getString(NDTConstants.BUNDLE_NAME,
                                               "oc48Str", null, Main.locale);
      case NDTConstants.DATA_RATE_10G_ETHERNET:
        return NDTConstants.RMANAGER.getString(NDTConstants.BUNDLE_NAME,
                                               "tengigabitEthernetStr", 
                                               null, Main.locale); 
      default:
        TestResults.appendErrMsg("No matching value for Data Speed.");
      } // end switch
      return null;
    } // prttxt() method ends
  }
}
