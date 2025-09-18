// Пины энкодеров
#define PIN_L_A 2  // Пин для сигнала 1
#define PIN_L_B 3  // Пин для сигнала 2

volatile long int global_pos_L = 0;

// Для прерываний (машины состояний)
bool ReadPIN_L_A_A;
bool ReadPIN_L_B_A;
bool ReadPIN_L_A_B;
bool ReadPIN_L_B_B;

// Функции на прерывания для считывания изменения меток с каждого канала
// Функции идентичны, только для разных каналов

void Read_L_A(){
  ReadPIN_L_A_A = digitalRead(PIN_L_A);
  ReadPIN_L_B_A = digitalRead(PIN_L_B);

  switch (ReadPIN_L_A_A) {
    case 0:
      if (ReadPIN_L_B_A == 1) {global_pos_L++; break;}
      if (ReadPIN_L_B_A == 0) {global_pos_L--; break;}
      break;
    
    case 1:
      if (ReadPIN_L_B_A == 1) {global_pos_L--; break;}
      if (ReadPIN_L_B_A == 0) {global_pos_L++; break;}
      break;
  }
  Serial.println(global_pos_L);
}

void Read_L_B(){
  ReadPIN_L_A_B = digitalRead(PIN_L_A);
  ReadPIN_L_B_B = digitalRead(PIN_L_B);

  switch (ReadPIN_L_B_B) {
    case 0:
      if (ReadPIN_L_A_B == 1) {global_pos_L--; break;}
      if (ReadPIN_L_A_B == 0) {global_pos_L++; break;}
      break;
    
    case 1:
      if (ReadPIN_L_A_B == 1) {global_pos_L++; break;}
      if (ReadPIN_L_A_B == 0) {global_pos_L--; break;}
      break;
  }
  Serial.println(global_pos_L);
}

void setup() {
  // Объявление прерываний
  attachInterrupt(0, Read_L_A, FALLING);
  attachInterrupt(1, Read_L_B, FALLING);

  pinMode(PIN_L_A, INPUT);
  pinMode(PIN_L_B, INPUT);

    // Подключение последовательного порта для отладки
  Serial.begin(115200);
}

void loop() {
  
  }

 