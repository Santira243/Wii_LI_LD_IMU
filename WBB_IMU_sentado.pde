import de.voidplus.leapmotion.*;
import hypermedia.net.*;
import toxi.geom.*;            // Posee la clase quaternion con un par de utilidades encima

  int s;
  int m;
// VARIABLES WBB
//LeapMotion leap;
ArrayList<TimeoutButton> buttons = new ArrayList<TimeoutButton>();
ArrayList<PVector> cursors_IZQUIERDA = new ArrayList<PVector>();
ArrayList<PVector> cursors_DERECHA = new ArrayList<PVector>();

float X;
float TR;
float TL;
float BR;
float BL;

int tiempo;

boolean leer;

UDP udp_WBB;


// VARIABLES IMUS
public class posme
{
  float[] q = new float [4];
  boolean loaded;
}

// Variables de los cuaterniones
float[] q = new float[4];
Quaternion quat_1 = new Quaternion(1, 0, 0, 0);
Quaternion quat_2 = new Quaternion(1, 0, 0, 0);
Quaternion quat_z = new Quaternion(1, 0, 0, 0);

// Variables para miembro inferior
float[] pos_PuntoFijo = {0.0,0.0,0.0};    // Posición espacial del punto fijo de referencia
float[] pos_IMU   = {0.0,0.0,0.0};    // Posición espacial del IMU
int pos_vector = 0;          // Vector posición para el filtro promediador

// Variables para el filtro promediador
float[][] quat_1_m = new float [30][4];    // Filtrado de la posición del muslo
float[] quat_1_sum = new float [4];        // Para guardar la sumatoria de cuaterniones
Quaternion quat_1_PB = new Quaternion(1, 0, 0, 0);  // quat_1 con pasabajos
Quaternion quat_2_PB = new Quaternion(1, 0, 0, 0);  // quat_2 con pasabajos
float[] pos_PF_IMU = {0.0,0.0,0.0};    // Posición espacial del punto fijo

// Variables UDP IMU
UDP udp_IMU;
posme dev1 = new posme();
String message   = "1";          // Mensaje a enviar
String ip1       = "10.0.0.3";   // IP del IMU 1
int port         = 65506;        // Puerto de comunicación
  
// Otras variables IMU
float [] axis_q1;
float posicion;
float posicion_cero;

float aux;

boolean grabar_pos = false;
  
//------------------------------------------------------------------------//
void setup()
{
  size(1000, 600, P3D);
  tiempo = millis();
  buttons.add(new TimeoutButton(200, 150, 600, 400, 1));

  // UDP asociados al puerto de comunicación
  udp_WBB = new UDP( this, 4000);
  udp_WBB.listen( true );
  noStroke();
  
  udp_IMU = new UDP( this, 65506 );
  udp_IMU.listen( true );
  //udp_IMU.send( message, ip1, port );
    
  pos_PF_IMU[0] = 0.0;
  pos_PF_IMU[1] = 0.0;
  pos_PF_IMU[2] = -1.0;
  grabar_pos = false;
  posicion_cero = 0;

  
}
//------------------------------------------------------------------------//

float[] rot_q1 = quat_1_PB.toAxisAngle();

//------------------------------------------------------------------------//
void draw() 
{
  background(0);
  stroke(255);
  //-WBB
  cursors_IZQUIERDA.clear();
  cursors_DERECHA.clear();
  
  for (TimeoutButton b : buttons)
  {
    b.render(); // 
  }
  fill(0);
  textSize(30);
  text("Izquierda", 350, 300);
  text("Derecha", 650, 300); 

  strokeWeight(3);
  noFill();
  
  //-IMUS
  // Guardamos las rotaciones en las siguientes variables locales
  float[] axis_q1 = rot_q1;
  pushMatrix();
  // Ubicación punto fijo
  translate(width/2, height/2 );
  //Posición del punto fijo
  pos_PuntoFijo[0] = modelX(0, 0, 0);
  pos_PuntoFijo[1] = modelY(0, 0, 0);
  pos_PuntoFijo[2] = modelZ(0, 0, 0);
      
  //Sistema punto fijo - persona
  pushMatrix();
  rotate(axis_q1[0], axis_q1[1], axis_q1[3], axis_q1[2]); // Rotación del IMU 1
  translate(0, -200, 0);
  //Guardamos las coordenadas en las que se ubica el IMU
  pos_IMU[0] = modelX(0, 0, 0);
  pos_IMU[1] = modelY(0, 0, 0);
  pos_IMU[2] = modelZ(0, 0, 0);
  popMatrix();

  popMatrix();
  
  
  aux = map(-pos_IMU[2],-200,200,-300,300);
  posicion = aux + width/2 + posicion_cero;
  fill(255,100,0);
  if( posicion > 800 )
  { posicion = 800;}
  if (posicion < 200)
  { posicion = 200;}
  circle( posicion  , 100,20);
  //circle(aux+width/2+posicion_cero,150,20);
  //println("POSICION: ",posicion);
  //println("POS_IMU: ",-pos_IMU[2]);
  //println("CERO: ",aux);
  //text( -pos_IMU[2]+width/2,50,50);
}
//------------------------------------------------------------------------//

//------------------------------------------------------------------------//
void receive( byte[] data, String ip1, int port ) 
{  
  data = subset(data, 0, data.length);
  String message = new String( data );
  // Lee IMUS
  if( port == 65506)
  {
    // Traemos los datos que mandan los IMU por JSON
    JSONObject json = parseJSONObject(message);
    // Detecta errores, o se fija cuál IMU es y guarda la info en las variables correspondientes
    if (json == null)
    {
      println("JSONObject could not be parsed"); // Señal de error
    }
    else 
    {
      int disp =  json.getInt("Device"); // Lee el número de dispositivo (se lo dimos en el código de Arduino)
      if(disp == 1)
      {
        dev1.q[0] = ( json.getFloat("Q0"));  // qw
        dev1.q[1] = ( json.getFloat("Q1"));  // qx
        dev1.q[2] = ( json.getFloat("Q2"));  // qy
        dev1.q[3] = ( json.getFloat("Q3"));  // qz
        
        quat_1.set(dev1.q[0], dev1.q[1], dev1.q[2], dev1.q[3]); // Guarda la info del cuaternión en quat_1
        dev1.loaded = true;  // Indica que el dispositivo fue leído exitosamente
      }
    }
    // Movemos el puntero
    pos_vector++;
    if (pos_vector > 29)
    {
      pos_vector = 0;
    } 
    
    // Guardamos la info correspondiente en los vectores/matrices
    quat_1_m[pos_vector][0] = dev1.q[0];
    quat_1_m[pos_vector][1] = dev1.q[1];
    quat_1_m[pos_vector][2] = dev1.q[2];
    quat_1_m[pos_vector][3] = dev1.q[3];
    
    quat_1_PB.set(0,0,0,0);      
    
    quat_1_sum[0] = 0.0; quat_1_sum[1] = 0.0; quat_1_sum[2] = 0.0; quat_1_sum[3] = 0.0;
    
    // Hacemos sumatoria
    for (int i = 0; i <= 29; i++)
    {
      quat_1_sum[0] += quat_1_m[i][0];
      quat_1_sum[1] += quat_1_m[i][1];
      quat_1_sum[2] += quat_1_m[i][2];
      quat_1_sum[3] += quat_1_m[i][3];
    }         
    // Dividimos por el total de elementos para obtener el promedio    
    quat_1_PB.set(quat_1_sum[0]/30,quat_1_sum[1]/30,quat_1_sum[2]/30,quat_1_sum[3]/30);
               
    // Guardamos la info angular
    rot_q1 = quat_1_PB.toAxisAngle();       
          
    // Armamos dos vectores para poder calcular el ángulo entre Punto Fijo e IMU
    float [] PF_IMU = {0.0,0.0,0.0};
    PF_IMU[0] = pos_PuntoFijo[0] - pos_IMU[0];
    PF_IMU[1] = pos_PuntoFijo[1] - pos_IMU[1];
    PF_IMU[2] = pos_PuntoFijo[2] - pos_IMU[2];
    
    //Grabar la posicion correcta del IMU
    if( grabar_pos)
    {
      //circle( -pos_IMU[2]+width/2, 100,20)
      posicion_cero = pos_IMU[2];
      grabar_pos = false;
    } 
    
    dev1.loaded = false;
  }
  else
  {
    data = subset(data,0,data.length-2);
    String message_wbb = new String( data );
    String []nums = split(message_wbb,",");
    float []vals = float(nums);
    if(message.indexOf("Top_right") > 0)
    {TR=vals[4];}
    if(message.indexOf("Top_Left") > 0)
    {TL=vals[4];}
    if(message.indexOf("Bottom_Right") > 0) 
    {BR=vals[4];}
    if(message.indexOf("Bottom_Left") > 0) 
    {BL=vals[4];}
  
    if(TR < 5  && TL < 5 && BR < 5 && BL < 5) 
    { 
      X=0;
      leer = false;
    }
  
    if(leer == true)
    {
      if(data.length >90)
      {
        X = vals[4];
      }
    }
    else
    {
      if(TR >5  && TL > 5 && BR >5 && BL > 5)
      {
        leer = true;
      }
    }
  }
}
//------------------------------------------------------------------------//

//------------------------------------------------------------------------//
void keyPressed()
{
  if (key == 'x')
  {
    grabar_pos = true;
    tiempo = millis();
    m = 0;
    s = 0;
  }
}
//------------------------------------------------------------------------//
