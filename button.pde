class TimeoutButton
{
  int x;
  int y;
  int w;
  int h;

  
  float timeout;
  float P_d = 0;
  float P_i = 0;
  float izq_porcentaje;
  float der_porcentaje;
  float aux;
  
  boolean inside;
  boolean inside_D ;
  
  int startFrame;
  int showPress_I = 0;
  int showPress_D = 0;
  
  float secInside = -1;
  float secInside_IZQUIERDA = -1;
  float secInside_DERECHA = -1;


  TimeoutButton(int x, int y, int w, int h, float timeout)
  {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.timeout = timeout;
  }

// GRAFICAS, PROGRESO, BARRA DE FUERZA //
  void render() 
  {
    if (showPress_I > 0)
    {
      fill(100);
      showPress_I--;
    } 
    else
    {
      fill(100);
    }
    
    if (showPress_D > 0)
    {
      fill(100);
      showPress_D--;
    } 
    else
    {
      fill(100);
    }
    
    stroke(255);
    rect(x, y, w, h); //P
    //rect(10,y,30,h);
    //line(10,350,40,350);
    line(500,y,500,h+y);
    stroke(255);
    noStroke();   
    
  // TIEMPO //
   s=(millis()-tiempo)/1000;
   if(s < 60)
   {
     fill (255);
     textSize(40);
     textAlign(CENTER);
     text("TIEMPO",width/2 - 100,50);
     text(m+":"+s,width/2 + 50, 50);
     s = s+1;
   }
   else
   {
     tiempo = millis();
     m = m + 1;
     s = 0;
   }
    
   
  // PROGRESO Y BARRA DE FUERZA //
   if (X<0) 
   {
     P_i=map(X,-15,0,0,1);
     P_i=1-P_i;
     secInside = P_i;
       
     P_d = P_d - P_i/(50*timeout);
     if (P_i > 1)
     {
       P_i = 1;
     }
     if (P_d < 0)
     {pressed_D();}
     
     // PROGRESO
     izq_porcentaje = map(P_i, 0, 1, 0, 100);
     int neWizq_porcentaje = int(izq_porcentaje);
     der_porcentaje = map(P_d, 0, 1, 0, 100);
     int neWder_porcentaje = int(der_porcentaje);
     fill(0,255, 0);
     rect(700-x, y, -P_i*w/2, h);
     fill(0,0,255);
     rect(x+300, y, P_d*w/2, h);
     fill(255);
     textSize(40);
     text(neWizq_porcentaje, 130, 300);
     text("%", 180, 300);
     text(neWder_porcentaje, 835, 300);
     text("%", 885, 300);
   }
   
   if (X>0)
   {
     P_d=map(X,0,15,0,1);
     P_d=P_d;
     secInside_DERECHA = P_d;
     P_i = P_i - P_d/(50*timeout);
     if (P_d > 1)
     {
       P_d = 1;
     }
     if (P_i < 0)
     {
       pressed_I();
     } 
     
     //PROGRESO
     
     izq_porcentaje = map(P_i, 0, 1, 0, 100);
     int neWizq_porcentaje = int(izq_porcentaje);
     der_porcentaje = map(P_d, 0, 1, 0, 100);      
     int neWder_porcentaje = int(der_porcentaje);
     fill(0, 0, 255);
     rect(x+300, y, P_d*w/2, h);
     fill(0,255,0);
     rect(700-x, y, -P_i*w/2,  h);
     fill(255);
     textSize(40);
     text(neWizq_porcentaje, 130, 300);
     text("%", 180, 300);
     text(neWder_porcentaje, 835, 300);
     text("%", 885, 300);
   }
 }
  
 void pressed_I()
 {
    showPress_I = 1;
    secInside = -1;
    P_i = 0;
  }
   
  void pressed_D()
  {
    showPress_D = 1;
    secInside_DERECHA = -1;
    P_d = 0;
   }
 
}
