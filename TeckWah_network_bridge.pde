/*
 Author: Benjamin Low (benjamin.low@digimagic.com.sg)
 Last updated: 5 Oct 2015
 Description: 
 Bridge program for Teck Wah for communicating between Flash and the USB networked Arduinos. 
 Data used are all strings, including text and numerical data. 
 Arduino should use "Serial.print" instead of "Serial.write" to send integers as strings and text strings as text strings. 
 The Flash client should send all data in the form of strings as well, including numbers. 
 This network bridge is just a echo program. All logic should be on client side.
 
 Note: Serial port names set to Macintosh. Need to rename for Windows.
 */

import processing.net.*;
import processing.serial.*;

final int NUM_ARDUINOS = 5; 
final int BAUDRATE = 9600;

Serial[] serialPorts = new Serial[NUM_ARDUINOS];
Server myServer;

//for incoming serial data
String serial_string = "", client_string = "", client_displayed_string = "";

//ASCII codes
int CR = 13;  // ASCII return   == 13 //
int LF = 10;  // ASCII linefeed == 10 //

void setup() {
        size(400, 400);

        println("Available serial ports: ");
        printArray(Serial.list());

        String[] textlines = loadStrings("settings.txt");

        String[] comport_numbers = new String[NUM_ARDUINOS+1]; //additional number is for server port

        for (int i=0; i<textlines.length; i++) {

                String[] a_number = split(textlines[i], '=');
                comport_numbers[i] = a_number[1];

                if (i<textlines.length-1) {    

                        serialPorts[i] = new Serial(this, "/dev/cu.usbmodem" + a_number[1], BAUDRATE);
                } else {
                        myServer = new Server(this, int(a_number[1]));
                }
        }    

        println();
        println("setting up...");
        println("RFID comport = " + comport_numbers[0]);
        println("CAPTOUCH comport = " + comport_numbers[1]);
        println("NEOPIXEL comport = " + comport_numbers[2]);
        println("LINEARACTUATOR comport = " + comport_numbers[3]);
        println("HERKULEX comport = " + comport_numbers[4]);
        println("SERVER port = " + comport_numbers[5]);
}

void draw() 
{
        background(0);

        // frame.setLocation(100, 100); //change to (-1000, -1000) to hide it

        text("From Arduino: " + serial_string, 20, 200);
        text("From client: " + client_displayed_string, 20, 300);

        listen_to_client();

        translate_client_for_arduino();
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
                        myServer.write(serial_string);
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
                                        client_displayed_string = client_string;
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

