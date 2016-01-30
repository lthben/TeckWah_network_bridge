/*
 Author: Benjamin Low (benjamin.low@digimagic.com.sg)
 
 Description: 
 Bridge program for Teck Wah for communicating between Flash and the USB networked Arduinos. 
 Data used are all strings, including text and numerical data. 
 Arduino should use "Serial.print" instead of "Serial.write" to send integers as strings and text strings as text strings. 
 The Flash client should send all data in the form of strings as well, including numbers. 
 This network bridge is just a echo program. All logic should be on client side.
 
 Last updated: 30 Jan 2016
 */

import processing.net.*;
import processing.serial.*;

//USER DEFINED SETTINGS
final int NUM_ARDUINOS = 11; 
OS this_OS = OS.MACOSX; //see other tab for enum def
boolean DEBUG = false; //to see print statements in the Processing IDE console
/*!!!IMPORTANT - define the comports according to the order in the settings.txt file in the other tab*/

Serial[] serialPorts;
SERIALPORTS serialPortIndex;

Server myServer;
final int BAUDRATE = 9600;

String from_client_string = "", from_arduino_string = "", from_client_string_display, from_arduino_string_display;
String[] comport_numbers;

//ASCII codes
int CR = 13;  // ASCII return   == 13 //
int LF = 10;  // ASCII linefeed == 10 //

boolean isDrawerOpen, isDisplayOpen; //keep track of the states of the two linear actuators

void setup() {
        
        size(400, 100);

        textSize(16);

        if (DEBUG) {
                println("this OS: " + this_OS);
                println("Available serial ports: ");
                printArray(Serial.list());
        }

        String[] textlines;

        serialPorts = new Serial[NUM_ARDUINOS];

        if (this_OS == OS.WINDOWS)  textlines = loadStrings("windows_settings.txt"); 
        else textlines = loadStrings("macosx_settings.txt"); 

        comport_numbers = new String[NUM_ARDUINOS+1]; //additional number is for server port

        for (int i=0; i<NUM_ARDUINOS+1; i++) {

                String[] a_number = split(textlines[i], '=');
                comport_numbers[i] = a_number[1];

                if (i<NUM_ARDUINOS) { //serial ports

                        if (this_OS == OS.MACOSX) serialPorts[i] = new Serial(this, "/dev/cu.usbmodem" + a_number[1], BAUDRATE); 
                        else if (this_OS == OS.WINDOWS) serialPorts[i] = new Serial(this, "COM" + a_number[1], BAUDRATE);
                } else { //server port
                        myServer = new Server(this, int(a_number[1]));
                }
        }
} 


void draw() 
{
        background(0);

        // frame.setLocation(100, 100); //change to (-1000, -1000) to hide it

        text("Server from arduino: " + from_arduino_string_display, 5, 33); 
        text("Server to arduino: " + from_client_string_display, 5, 66);

        //the arduino string is obtained in serialEvent()
        //process_arduino_string() is also called in serialEvent()

        clientEvent();
}

void serialEvent(Serial mySerialPort) { //triggers whenever a serialPort message is received

        String my_buffer = "";
        int my_port_index = 99;

        for (int port_index=0; port_index<NUM_ARDUINOS; port_index++) {
                if (mySerialPort == serialPorts[port_index]) {
                        my_port_index = port_index;
                }
        }

        my_buffer = mySerialPort.readStringUntil(CR);

        if (my_buffer != null) {

                my_buffer = trim(my_buffer); 

                if (my_buffer.length() > 0 ) {

                        if (DEBUG) println("port: " + my_port_index + '\t' + "message: " + my_buffer);

                        from_arduino_string = my_buffer;

                        from_arduino_string_display = from_arduino_string;

                        process_arduino_string(from_arduino_string);

                        myServer.write(from_arduino_string); //automatically echo from serial to server port

                        from_arduino_string = "";
                        my_buffer = ""; //reset the string
                }
        }
}

void process_arduino_string(String the_string) {       
        //refer to command list in the respective Arduino sketches for what char to write

        if (the_string.equals("touch1_detected")) serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('0'); //button1
        else if (the_string.equals("touch1_released")) serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('1');
        else if (the_string.equals("touch2_detected")) serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('2'); //button2
        else if (the_string.equals("touch2_released")) serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('3');
        else if (the_string.equals("1tag_1")) serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('4'); //ring1  
        else if (the_string.equals("1tag_2")) serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('5');
        else if (the_string.equals("1tag_3")) serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('6');
        else if (the_string.equals("1tag_4")) serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('7');
        else if (the_string.equals("1no_tag") && isDrawerOpen) serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('8');
        else if (the_string.equals("2tag_1")) serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('a'); //ring2        
        else if (the_string.equals("2tag_2")) serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('b');
        else if (the_string.equals("2tag_3")) serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('c');
        else if (the_string.equals("2tag_4")) serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('d');
        else if (the_string.equals("2no_tag") && isDrawerOpen) serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('e');
}


void clientEvent() {

        Client thisClient = myServer.available(); 

        String my_buffer = "";

        if (thisClient != null) {

                if (thisClient.available() > 0) 
                {           
                        my_buffer = thisClient.readString();      

                        if (my_buffer != null) {

                                my_buffer = my_buffer.trim();

                                if (my_buffer.length()>0) {

                                        from_client_string = my_buffer;

                                        process_client_string();
                                }
                        }
                }
        }
}

void process_client_string() {
        //refer to command list in the respective Arduino sketches for what char to write


        if (from_client_string.length() > 0) {

                if (from_client_string.equals("light1_on")) {
                        serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('m'); //turn on panel 1
                } else if (from_client_string.equals("light1_off")) {
                        serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('n'); //turn off panel 1
                } else if (from_client_string.equals("light2_on")) {
                        serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('o'); //turn on panel 1
                } else if (from_client_string.equals("light2_off")) {
                        serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('p'); //turn off panel 1
                } else if (from_client_string.equals("light3_on")) {
                        serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('q'); //turn on panel 1
                } else if (from_client_string.equals("light3_off")) {
                        serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('r'); //turn off panel 1
                } else if (from_client_string.equals("light4a_on")) { 
                        serialPorts[serialPortIndex.NEOPIXEL_1_COMPORT.ordinal()].write('1'); //long trail forward animation    
                        activate_steppers(1); //cw rotation
                } else if (from_client_string.equals("light4b_on")) {
                        serialPorts[serialPortIndex.NEOPIXEL_1_COMPORT.ordinal()].write('2'); //long trail reverse animation
                        activate_steppers(2); //ccw rotation
                } else if (from_client_string.equals("light5_on")) {
                        serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('g'); //turn on display 1
                } else if (from_client_string.equals("light5_off")) {
                        serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('h'); //turn off display 1
                } else if (from_client_string.equals("light6_on")) {
                        serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('i'); //turn on display 2
                } else if (from_client_string.equals("light6_off")) {
                        serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('j'); //turn off display 2
                } else if (from_client_string.equals("light7_on")) {
                        serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('k'); //turn on display 3
                } else if (from_client_string.equals("light7_off")) {
                        serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('l'); //turn off display 3
                } else if (from_client_string.equals("light8_on")) {
                        serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('u'); //turn on map2 (single pixels)
                } else if (from_client_string.equals("light8_off")) {
                        serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('v'); //turn off map2
                } else if (from_client_string.equals("light9_on")) {
                        serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('s'); //turn on map1 (world map)
                } else if (from_client_string.equals("light9_off")) {
                        serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('t'); //turn off map1
                } else if (from_client_string.equals("light10_on")) {
                        serialPorts[serialPortIndex.NEOPIXEL_1_COMPORT.ordinal()].write('3'); //turn on achievement
                } else if (from_client_string.equals("light10_off")) {
                        serialPorts[serialPortIndex.NEOPIXEL_1_COMPORT.ordinal()].write('4'); //turn off achievement
                } else if (from_client_string.equals("drawer_close")) {
                        isDrawerOpen =false;
                        serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('9'); //turn off ring1
                        serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('f'); //turn off ring2
                        serialPorts[serialPortIndex.LINEAR_ACT_1_COMPORT.ordinal()].write('0'); //retract actuator
                } else if (from_client_string.equals("drawer_open")) {
                        isDrawerOpen = true;
                        serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('8'); //waiting mode for ring1
                        serialPorts[serialPortIndex.NEOPIXEL_2_COMPORT.ordinal()].write('e'); //waiting mode for ring2
                        serialPorts[serialPortIndex.LINEAR_ACT_1_COMPORT.ordinal()].write('1'); //extend actuator
                } else if (from_client_string.equals("display_close")) {
                        isDisplayOpen = false;
                        serialPorts[serialPortIndex.LINEAR_ACT_2_COMPORT.ordinal()].write('0'); //retract actuator
                } else if (from_client_string.equals("display_open")) {
                        isDisplayOpen = true;
                        serialPorts[serialPortIndex.LINEAR_ACT_2_COMPORT.ordinal()].write('1'); //extend actuator
                } 

                from_client_string_display = from_client_string;
                from_client_string = ""; //reset the string
        }
}

void activate_steppers(int dir) {

        if (dir == 1) {
                serialPorts[serialPortIndex.STEPPER_1_COMPORT.ordinal()].write('1'); //cw rotation
                serialPorts[serialPortIndex.STEPPER_2_COMPORT.ordinal()].write('1');
                serialPorts[serialPortIndex.STEPPER_3_COMPORT.ordinal()].write('1');
        } else if (dir == 2) {
                 serialPorts[serialPortIndex.STEPPER_1_COMPORT.ordinal()].write('2'); //ccw rotation
                serialPorts[serialPortIndex.STEPPER_2_COMPORT.ordinal()].write('2');
                serialPorts[serialPortIndex.STEPPER_3_COMPORT.ordinal()].write('2');
        }
}


