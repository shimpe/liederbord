const int selectPin0 = 2;
const int selectPin1 = 3;
const int selectPin2 = 4;
const int selectPin3 = 5;

const int ldrPin = A0;

int readMux(int index) {
   
   int controlPin[] = {selectPin0, selectPin1, selectPin2, selectPin3};
   
   int muxChannel[16][4]={
    {0,0,0,0}, //channel 0
    {1,0,0,0}, //channel 1
    {0,1,0,0}, //channel 2
    {1,1,0,0}, //channel 3
    {0,0,1,0}, //channel 4
    {1,0,1,0}, //channel 5
    {0,1,1,0}, //channel 6
    {1,1,1,0}, //channel 7
    {0,0,0,1}, //channel 8
    {1,0,0,1}, //channel 9
    {0,1,0,1}, //channel 10
    {1,1,0,1}, //channel 11
    {0,0,1,1}, //channel 12
    {1,0,1,1}, //channel 13
    {0,1,1,1}, //channel 14
    {1,1,1,1}  //channel 15
  };

  for (int i=0; i<4; ++i) {
    digitalWrite(controlPin[i], muxChannel[index][i]);
  }
  int value = analogRead(ldrPin);
  delay(1);
  return value;
}

void setup() {
  Serial.begin(9600);
  
  while (!Serial) {
    ; // wait for serial port to connect. Needed for native USB port only
  }
  
  pinMode(selectPin0, OUTPUT);
  pinMode(selectPin1, OUTPUT);
  pinMode(selectPin2, OUTPUT);
  pinMode(selectPin3, OUTPUT);
  pinMode(ldrPin, INPUT);
  digitalWrite(selectPin0, LOW);
  digitalWrite(selectPin1, LOW);
  digitalWrite(selectPin2, LOW);
  digitalWrite(selectPin3, LOW);
}

void loop() {
  
  Serial.print("@");
  
  for (int i=0; i<16; ++i) {
    int sensorValue = 0;
    Serial.print(readMux(i));
    Serial.print(";");
  }
   
  Serial.print("#");
  
  delay(10);
  
}
