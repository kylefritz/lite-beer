#include <EEPROM.h>

#include <Servo.h>

const int OFFSET = 180;
char serialIn;

/****** Pin declarations ******/
// drink / return drink
const int drinkpin        = 2; /* red dot */

// servos
const int xyservopin  = 7;
const int zservo1pin  = 6;
const int zservo2pin  = 5;

/****** memory addresses  ******/
const int eeprom_rest_xy = 0;
const int eeprom_rest_z  = 1;
const int eeprom_drink_xy = 2;
const int eeprom_drink_z  = 3;

/****** Saved Settings ******/
int memory_rest_xy = 0;
int memory_rest_z  = 0;
int memory_drink_xy = 0;
int memory_drink_z  = 0;

//deplays
const int ANGLE_DELAY=50;
const int PITCH_DELAY=50;

// global vars
Servo xyservo;
Servo zservo1;
Servo zservo2;
const int SERVO_XY = 0;
const int SERVO_Z = 1;
int currentServo;

const int DRINK  = 1;
const int REST  = 2;

int state = REST;

int trainAngle=0;
int trainPitch=0;
int trainState=REST;
boolean exitTrain=false;

void setup(){
  xyservo.attach(xyservopin);
  zservo1.attach(zservo1pin);
  zservo2.attach(zservo2pin);
  Serial.begin(9600);
  
  memory_rest_xy = EEPROM.read(eeprom_rest_xy);
  memory_rest_z = EEPROM.read(eeprom_rest_z);
  memory_drink_xy = EEPROM.read(eeprom_drink_xy);
  memory_drink_z = EEPROM.read(eeprom_drink_z);

  Serial.print("XY rest = ");
  Serial.print(memory_rest_xy);
  Serial.print("\nZ rest = ");
  Serial.print(memory_rest_z);
  Serial.print("\nXY drink = ");
  Serial.print(memory_drink_xy);
  Serial.print("\nZ drink = ");
  Serial.print(memory_drink_z);
  Serial.print("\n");

  /* If eeprom has no values yet... */
  if(memory_rest_xy >= 180) { memory_rest_xy = 0;}
  if(memory_rest_z  >= 180) { memory_rest_z = 0;}  
  if(memory_drink_xy >= 180) { memory_drink_xy = 0;}
  if(memory_drink_z  >= 180) { memory_drink_z = 0;}  
 
  //slow way
  setPitchAngle(memory_rest_z,memory_rest_xy);
  
  pinMode(drinkpin, INPUT);
}


void loop(){
    serialIn = Serial.read();
    
    // normal operation
    if(digitalRead(drinkpin) == 1 || serialIn=='b'){
      
      changeState();
      
    }else if(serialIn=='t'){
      
      train();
      
    }
}

void changeState(){
  if(state==REST){
    Serial.println("Normal button- raising for drink");

    setPitchAngle(memory_drink_z,memory_drink_xy);
    
    state = DRINK;
    debounce(drinkpin);
  }else if(state== DRINK){
    Serial.println("Normal button- lowering to rest");

    setPitchAngle(memory_rest_z,memory_rest_xy);          
    
    state = REST;
    debounce(drinkpin);
  }
}

void train(){
  exitTrain=false;
  Serial.println("training");
  Serial.println("train rest");
  Serial.println("axis +/- 'a','z','s','x'. switch 'b'. remind 'r'. save 'q'. exit 't'.");
  
  while(!exitTrain){
    if (Serial.available() > 0) {
       serialIn = Serial.read();
       switch(serialIn){
         case 'a':
           Serial.println("plus xy");
           trainAngle+=2;
           setAngle(trainAngle);
           break;
         case 'z':
           Serial.println("minus xy");
           trainAngle-=2;
           setAngle(trainAngle);
           break;
         case 's':
           Serial.println("plus z");
           trainPitch+=2;
           setPitch(trainPitch);
           break;
         case 'x':
           Serial.println("minus z");
           trainPitch-=2;
           setPitch(trainPitch);
           break;
         case 'b':
           if(trainState==REST){
             Serial.println("switch to drink");
             trainState=DRINK;
             //goto
             setPitchAngle(memory_drink_z,memory_drink_xy);
           }else{
             Serial.println("switch to rest");
             trainState=REST;
             //goto Rest
             setPitchAngle(memory_rest_z,memory_rest_xy);
           }
           break;
         case 'r':
           if(trainState==REST){
             Serial.println("reminder: rest");
           }else{
             Serial.println("reminder: drink");
           }
         break;
         case 'q':
           if(trainState==REST){
             Serial.println("save to rest");
             
             EEPROM.write(eeprom_rest_xy, trainAngle);
             EEPROM.write(eeprom_rest_z , trainPitch);
             memory_rest_xy=trainAngle;
             memory_rest_z=trainPitch;
          
           }else{
             Serial.println("save to drink");
             
             EEPROM.write(eeprom_drink_xy, trainAngle);
             EEPROM.write(eeprom_drink_z , trainPitch);
             memory_drink_xy = trainAngle;
             memory_drink_z  = trainPitch;
           }
           break;
         case 't':
           Serial.println("exit train");
           exitTrain=true;
           break;
        default:
          Serial.print("dont know: ");
          Serial.print(serialIn);
          Serial.print("\n");
           break;
        } 
    }
  }
}

void debounce(int pin){
  delay(50);
  while(digitalRead(pin)==1){delay(50);} 
}

void setPitch(int angle){
  int startangle = zservo1.read();
  
  Serial.print("Starting pitch ");
  Serial.print (startangle);  
  Serial.print(" ; ending pitch ");
  Serial.print (angle);
  Serial.print("\n");

  if(angle<startangle){
    for(int i=startangle; i>angle; i-=2){
      zservo1.write(i);
      zservo2.write(OFFSET-i);
      delay(PITCH_DELAY);
    }
  }else{
    for(int i=startangle; i<angle; i+=2){
      zservo1.write(i);
      zservo2.write(OFFSET-i);
      delay(PITCH_DELAY);
    }
  }
}

void setAngle(int angle){
  int startangle = xyservo.read();
  int i;

  Serial.print("Starting angle ");
  Serial.print (startangle);  
  Serial.print(" ; ending angle ");
  Serial.print (angle);
  Serial.print("\n");
  
  if(angle<startangle){
    for(i=startangle; i>angle; i-=2){
      xyservo.write(i); 
      delay(ANGLE_DELAY);
    }
  }else{
    for(i=startangle; i<angle; i+=2){
      xyservo.write(i); 
      delay(ANGLE_DELAY);
    }
  }
}

void setPitchAngle(int pitch,int angle){
   setPitch(pitch);
   setAngle(angle);
}

