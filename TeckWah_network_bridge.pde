/*
 Author: Benjamin Low (benjamin.low@digimagic.com.sg)
 
 Description: 
 Bridge program for Teck Wah for communicating between Flash and the USB networked Arduinos. 
 Data used are all strings, including text and numerical data. 
 Arduino should use "Serial.print" instead of "Serial.write" to send integers as strings and text strings as text strings. 
 The Flash client should send all data in the form of strings as well, including numbers. 
 This network bridge is just a echo program. All logic should be on client side.
  
 Last updated: 30 Dec 2015
 */

import processing.net.*;
import processing.serial.*;

//USER DEFINED SETTINGS
final int NUM_ARDUINOS = 13; 

Serial[] serialPorts = new Serial[NUM_ARDUINOS];
Server myServer;
final int BAUDRATE = 9600;

//for incoming serial data
String serial_string = "", client_string = "", from_arduino_string = "";
String[] comport_numbers;

//ASCII codes
int CR = 13;  // ASCII return   == 13 //
int LF = 10;  // ASCII linefeed == 10 //

void setup() {
        size(400, 100);
        
        textSize(16);

        println("Available serial ports: ");
        printArray(Serial.list());

        String[] textlines = loadStrings("settings.txt");

        comport_numbers = new String[NUM_ARDUINOS+1]; //additional number is for server port

        for (int i=0; i<textlines.length; i++) {

                String[] a_number = split(textlines[i], '=');
                comport_numbers[i] = a_number[1];

                if (i<textlines.length-1) { //serial ports

                        //serialPorts[i] = new Serial(this, "/dev/cu.usbmodem" + a_number[1], BAUDRATE); //for MacOSX
                        //serialPorts[i] = new Serial(this, "COM" + a_number[1], BAUDRATE); //for Windows
                        
                } else { //server port
                        myServer = new Server(this, int(a_number[1]));
                }
        }    
}

void draw() 
{
        background(0);

        // frame.setLocation(100, 100); //change to (-1000, -1000) to hide it
        
        display_text();

        listen_to_client();

        translate_client_for_arduino();
}

void keyPressed() {
    
    switch(key) {
     case('1'):
     from_arduino_string = "light4_finished";
     break;
     case('2'):
     from_arduino_string = "light10_finished";
     break;
     case('3'):
     from_arduino_string = "touch1_activated";
     break;
     case('4'):
     from_arduino_string = "touch2_activated";
     break;
     case('5'):
     from_arduino_string = "tag_1";
     break;
     case('6'):
     from_arduino_string = "tag_2";
     break;
     case('7'):
     from_arduino_string = "tag_3";
     break;
     case('8'):
     from_arduino_string = "tag_4";
     break;      
     default:
     break;
    }
    
    myServer.write(from_arduino_string);
}

void display_text() {
    
        //text("From Arduino: " + serial_string, 20, 200); //from actual arduino
        text("Server from arduino: " + from_arduino_string, 5, 33); //simulated by keyboard press
        text("Server to arduino: " + client_string, 5, 66);
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
                serial_string = trim(my_buffer); 
                if (serial_string.length() > 0 ) {
                        //                println("port: " + my_port_index + '\t' + "message: " + in_string);
                        //myServer.write(serial_string); //echo from serial to server port
                }
        }
}


void listen_to_client() {

        Client thisClient = myServer.available();   

        String my_buffer = "";

        if (thisClient != null) {
            
                if (thisClient.available() > 0) 
                {           
                        my_buffer = thisClient.readString();      

                        if (my_buffer != null) {
                            
                                my_buffer = my_buffer.trim();
                                
                                if (my_buffer.length()>0) {

                                        client_string = my_buffer;
                                }
                        }
                }
        }
}

void translate_client_for_arduino() {
    
        if (client_string.length() > 0) {
            
                if (client_string.equals("open_drawer")) {
                        
                        serialPorts[3].write('1');
                        client_string = ""; //to stop sending over and over again
                        
                } else if (client_string.equals("close_drawer")) {
                        
                        serialPorts[3].write('2');
                        client_string = "";
                        
                } else if (client_string.equals("light_effect_1")) {
                        
                        serialPorts[2].write('1');
                        client_string = "";
                        
                } else if (client_string.equals("light_effect_2")) {
                        
                        serialPorts[2].write('2');
                        client_string = "";
                        
                } else if (client_string.equals("light_effect_3")) {
                        
                        serialPorts[2].write('3');
                        client_string = "";
                        
                } else if (client_string.equals("light_effect_4")) { //turn off motors and lights
                        
                        serialPorts[2].write('0');
                        serialPorts[4].write('q');
                        serialPorts[4].write('w');
                        client_string = "";
                        
                } else if (client_string.equals("spin_motors")) {
                        
                        serialPorts[4].write('o');
                        serialPorts[4].write('p');
                        serialPorts[4].write('7');
                        serialPorts[4].write('8');
                        client_string = "";
                }
        }
}