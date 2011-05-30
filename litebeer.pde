#include <EEPROM.h>

#include <Servo.h>

const int OFFSET = 180;
char serialIn;

/****** Pin declarations ******/
// drink / return drink
const int drinkpin        = 2; /* red dot */

// servos
const int xyservopin =7;
const int zservo1pin  =6;
const int zservo2pin  = 5 ;

/****** memory addresses  ******/
const int eeprom_chill_xy = 0;
const int eeprom_chill_z  = 1;
const int eeprom_drink_xy = 2;
const int eeprom_drink_z  = 3;

/****** Saved Settings ******/
int memory_chill_xy = 0;
int memory_chill_z  = 0;
int memory_drink_xy = 0;
int memory_drink_z  = 0;

// global vars
Servo xyservo;
Servo zservo1;
Servo zservo2;
const int SERVO_XY = 0;
const int SERVO_Z = 1;
int currentServo;

const int DRINK  = 1;
const int REST  = 2;

int joystick=0;
int state = REST;
int trainState=REST;
boolean exitTrain=false;

void setup(){
  xyservo.attach(xyservopin);
  zservo1.attach(zservo1pin);
  zservo2.attach(zservo2pin);
  Serial.begin(9600);
  
  memory_chill_xy = EEPROM.read(eeprom_chill_xy);
  memory_chill_z = EEPROM.read(eeprom_chill_z);
  memory_drink_xy = EEPROM.read(eeprom_drink_xy);
  memory_drink_z = EEPROM.read(eeprom_drink_z);

  Serial.print("XY rest = ");
  Serial.print(memory_chill_xy);
  Serial.print("\n Z rest = ");
  Serial.print(memory_chill_z);
  Serial.print("\n XY drink = ");
  Serial.print(memory_drink_xy);
  Serial.print("\n Z drink = ");
  Serial.print(memory_drink_z);
  Serial.print("\n");

  /* If eeprom has no values yet... */
  if(memory_chill_xy >= 180) { memory_chill_xy = 0;}
  if(memory_chill_z  >= 180) { memory_chill_z = 0;}  
  if(memory_drink_xy >= 180) { memory_drink_xy = 0;}
  if(memory_drink_z  >= 180) { memory_drink_z = 0;}  
 
  //slow way
  //setPitch(memory_chill_z);
  //setAngle(memory_chill_xy);
  
  //fast way
  //zservo1.write(memory_chill_z);
  //zservo2.write(OFFSET-memory_chill_z);            
  //xyservo.write(memory_chill_xy);
  
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

    //setPitch(memory_drink_z);
    //setAngle(memory_drink_xy);
    
    state = DRINK;
    debounce(drinkpin);
  }else if(state== DRINK){
    Serial.println("Normal button- lowering to rest");

    //setPitch(memory_chill_z);
    //setAngle(memory_chill_xy);          
    
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
           break;
         case 'z':
           Serial.println("minus xy");
           break;
         case 's':
           Serial.println("plus z");
           break;
         case 'x':
           Serial.println("minus z");
           break;
         case 'b':
           if(trainState==REST){
             Serial.println("switch to drink");
             trainState=DRINK;
             //TODO: goto Drink
           }else{
             Serial.println("switch to rest");
             trainState=REST;
             //TODO: goto Rest
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
             //TODO:save to rest
           }else{
             Serial.println("save to drink");
             //TODO:save to drink
           }
           break;
         case 't':
           Serial.println("exit train");
           exitTrain=true;
           break;
        default:
          Serial.print("dont know: ");
          Serial.print(serialIn);
          Serial.println("");
           break;
        } 
    }
  }
}

/*


      //training state machine
      if(digitalRead(trainpin) == 1){
        isTrain=true;
        if(trainstate==TRAIN_CHILL_XY){
          Serial.println("Start training chill xy");

          //get to the old saved state for training
          setPitch(memory_chill_z);
          setAngle(memory_chill_xy);
          
          //manipulate the xy servo
          joystick=memory_chill_xy;
          currentServo=SERVO_XY;
          
          trainstate = TRAIN_CHILL_Z;
        } else if(trainstate==TRAIN_CHILL_Z){
          Serial.println("Save chill xy; start training chill z...");
          
          memory_chill_xy = joystick;
          EEPROM.write(eeprom_chill_xy, memory_chill_xy);
          
          //recall z chill as reference
          joystick=memory_chill_z;
          
          //manipulate z servo
          currentServo=SERVO_Z; 
          trainstate = TRAIN_DRINK_XY;
          
        } else if(trainstate==TRAIN_DRINK_XY){
          Serial.println("Save chill z; start training drink xy...");

          memory_chill_z = joystick; 
          EEPROM.write(eeprom_chill_z, memory_chill_z);
          
          //get old state for drinking
          setPitch(memory_drink_z);
          setAngle(memory_drink_xy);          
          
          //recall drink xy as reference
          joystick=memory_drink_xy;
          currentServo=SERVO_XY;
          
          trainstate = TRAIN_DRINK_Z;
        }else if(trainstate==TRAIN_DRINK_Z){
          Serial.println("Save drink xy; start training drink z...");
          memory_drink_xy = joystick; 
          EEPROM.write(eeprom_drink_xy, memory_drink_xy);
          
          //recall drink xy as reference
          joystick=memory_drink_z;
          currentServo=SERVO_Z;          
          
          trainstate = EXIT;
        }else if(trainstate==EXIT){
          Serial.println("Save drink z; training complete...");
          
          memory_drink_z = joystick; 
          EEPROM.write(eeprom_drink_z, memory_drink_z);
          
          trainstate  = TRAIN_CHILL_XY;
          
          //return to chill; ready for drink button press
          setPitch(memory_chill_z);
          setAngle(memory_chill_xy);
          
          state = CHILL;
          
          isTrain = false; 
        }
        if(isTrain){LEDcolor(trainstate);}
        else {LEDcolor(100);}
        
        debounce(trainpin);
        
      }

      //training joystick
      if(isTrain){
        if(digitalRead(joystick_up) == 1){
          delay(50);
          joystick++;
          if(joystick>180) joystick=180;
          if(currentServo==SERVO_Z){
            zservo1.write(joystick);
            zservo2.write(OFFSET-joystick);            
          } else {
            xyservo.write(joystick);
          }
        }else if(digitalRead(joystick_down) == 1){
          delay(50);
          joystick--;
          if(joystick<0) joystick=0;
          if(currentServo==SERVO_Z){
            zservo1.write(joystick);
            zservo2.write(OFFSET-joystick);   
          } else {
            xyservo.write(joystick);
          }
        }
      }
*/

void debounce(int pin){
  delay(50);
 while(digitalRead(pin)==1){delay(50);} 
}

const int PITCH_DELAY=50;

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

const int ANGLE_DELAY=50;

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

