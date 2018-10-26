 /*
 Valores para los botones
 */
int botonSecundarioX, botonSecundarioY;      // Position of square button
int botonPrincipalX, botonPrincipalY;  // Position of circle button
int tamanioBoton = 90;     // Diameter of rect
int tamanioBotonX = 90;     // Diameter of rect
int tamanioBotonY = 50;     // Diameter of rect
color botonColor, baseColor;
color botonHighlight;
color currentColor;
boolean botonSecundarioOver = false;
boolean botonPrincipalOver = false;
boolean cargando=false;

/*
controladores de estado
Los estados de la aplicación según su valor, 
indican qué funciones deben realizar o no
0 : Manú inicial
1 : Carga la fotografía
2 : Listo para procesar
3 : Muestra resultado de análisis
4 : Carga Famoso en la base de datos
5 : Muestra el resultado
*/
int estado;

//Utilizados para La manipilación de la imagen
JSONObject json; //Archivo JSON que contiene la base de datos
PImage imagen; // Se refiere a la imagen sobre la que se trabajará
String rutaImagen="";//"Imag002.jpg";
int numPunto; // controla el orden de evaluación de los puntos
String respuesta="";

/*
Utilizados para realizar el análisis del vector
*/
double unidadDeMedida; //desde el punto central superior de la boca, al punto central inferior de la boca
double[][] vectoresFamosos=new double[6][55];
double[] vector;
String nombresActores[];
int cantFamosos;
/*
Vectores
*/
Punto[] puntos; //almacena los 11 puntos a evaluar del famoso
Punto[] nuevosPuntos; // almacena los 11 puntos a evaluar de la imagen cargada por el usuario

String texto="";

void setup() {
  estado=0;
  cargando=false;
  respuesta="";
  size(1020,820);
  configurarMenu();
  nuevosPuntos = new Punto[11];
  numPunto=0;
  cargarVectores();
  vector = new double[55];
  //vectoresFamosos=new double[55];
}

void configurarMenu(){
  
  botonColor = color(110);
  botonHighlight = color(51);
  botonHighlight = color(204);
  baseColor = color(102);
  currentColor = baseColor;
  botonPrincipalX = 30;
  botonPrincipalY = 20;
  botonSecundarioX = 180;
  botonSecundarioY = 20; 
}

void draw() {
  if(estado==0){
    dibujarMenu();
    text(respuesta,350,200);
  }else if(estado==1){
    if(cargando==false){
      cargando=true;
      selectInput("Seleccione un archivo:", "archivoSeleccionado");
    }else{
      if(rutaImagen!=""){
        cargarFoto(rutaImagen);  
      }
    }
    
  }else if(estado==2){
    cargarFoto(rutaImagen);    
    if (botonPrincipalOver) {
      fill(botonHighlight);
    } else {
      fill(botonColor);
    }
    stroke(0);
    rect(botonPrincipalX, botonPrincipalY, tamanioBotonX, tamanioBotonY);
    fill(0);
    text("Analizar",botonPrincipalX+25,botonPrincipalY+30);
  }else if(estado==3){
    //estado=0;
    update(mouseX, mouseY);
    background(currentColor);
    rutaImagen="";
    text(respuesta,350,200);
      
    if (botonPrincipalOver) {
      fill(botonHighlight);
    } else {
      fill(botonColor);
    }
    stroke(0);
    rect(botonPrincipalX, botonPrincipalY, tamanioBotonX, tamanioBotonY);
    fill(0);
    text("Continuar",botonPrincipalX+20,botonPrincipalY+30);
  }
}

/*
Se encarga de determinar si el archivo fue cargado o se canceló la operación.
*/
void archivoSeleccionado(File selection) {
  if (selection == null) {
    estado=0;
    cargando=false;
  } else {
    rutaImagen=selection.getAbsolutePath();
  }
}

/*
Se encarga de mostrar los elementos de la ventana del menú principal
*/
void dibujarMenu(){
  update(mouseX, mouseY);
  background(currentColor);
  text(texto,100,200);
    
  if (botonPrincipalOver) {
    fill(botonHighlight);
  } else {
    fill(botonColor);
  }
  stroke(0);
  rect(botonPrincipalX, botonPrincipalY, tamanioBotonX, tamanioBotonY);
  fill(0);
  text("Cargar",botonPrincipalX+25,botonPrincipalY+30);
}


/*
Determina los posicionamientos del puntero
*/
void update(int x, int y) {
  if ( sobreBotonPrimario(botonPrincipalX, botonPrincipalY, tamanioBotonX,tamanioBotonY) ) {
    botonPrincipalOver = true;
    botonSecundarioOver = false;
  } else if ( sobreBotonSecundario(botonSecundarioX, botonSecundarioY, tamanioBotonX, tamanioBotonY) ) {
    botonSecundarioOver = true;
    botonPrincipalOver = false;
  } else {
    botonPrincipalOver = botonSecundarioOver = false;
  }
}

/*
Controla las acciones relacionadas al evento de 
dar click al mouse.
Es controlado por los estados.
*/
void mousePressed() {
  
  if(estado==0){
    if (botonPrincipalOver) {
       estado=1; 
    }
    
  }else if(estado==1){
    definirPunto(mouseX,mouseY);  
  }else if(estado==2){
   if (sobreBotonPrimario(botonPrincipalX, botonPrincipalY, tamanioBotonX,tamanioBotonY)) {
       print("vamos a analizar");
       respuesta="";
       generarVector();
       int contador=0;
       cantFamosos=6;
       boolean flag=true;
       int famosoSimilar=-1;
       double gradoSimilitud=-1;
       while(contador<cantFamosos){
         double resp=vectoresSemejantes(vectoresFamosos[contador],vector);
         if(resp>=0){
            if(famosoSimilar==-1){
              famosoSimilar=contador;
              gradoSimilitud=resp;
            }else if(resp<gradoSimilitud){
              famosoSimilar=contador;
              gradoSimilitud=resp;
            }
         }
         contador++;
       }
       if(famosoSimilar>=0){
          respuesta="La fotografía introducida corresponde al rostro de:" +nombresActores[famosoSimilar];
          estado=3;
          flag=false;
       }else{
         respuesta="No se reconoció a la persona en la fotografía"; 
         estado=3;
       }
       print(respuesta);
    }
  }else if(estado==3){
    setup();
  }
}

/*
Se encarga de generar el vector de las distancias existentes en las 55 posibles combinaciones de puntos
*/
boolean generarVector(){
   int contador=0;
   
   unidadDeMedida=calcularDistancia(nuevosPuntos[8],nuevosPuntos[9]);
   //print("Distancia: "+d1);
   //print("\n");
   int contador0=0;
   int contador1=0;
   int contador2=1;
   while(contador1<11){
    while(contador2<11){
      vector[contador0]=calcularDistancia(nuevosPuntos[contador1],nuevosPuntos[contador2])/unidadDeMedida; //Aquí se le asigna el valor escalar según la undidad de medida definida.
      contador2++;
      contador0++;
    }
     contador1++;
     contador2=contador1+1;
   }
   return true;  
}

boolean sobreBotonSecundario(int x, int y, int width, int height)  {
  if (mouseX >= x && mouseX <= x+width && 
      mouseY >= y && mouseY <= y+height) {
    return true;
  } else {
    return false;
  }
}

boolean sobreBotonPrimario(int x, int y,  int width, int height) {
  if (mouseX >= x && mouseX <= x+width && 
      mouseY >= y && mouseY <= y+height) {
    return true;
  } else {
    return false;
  }
}

/*
Se encarga de cargar la foto en la ventana (mostrarla)
*/
void cargarFoto(String foto){
  background(baseColor);
  imagen = loadImage(foto); 
  image(imagen, (width - (imagen.width*2))/2, (height-(imagen.height*2))/2, imagen.width*2, imagen.height*2);
  mostrarPuntos();
  if(estado==1){
    definirUbicacionPunto();
  }
}

/*
Crea un punto en la imangen
*/
void dibujarPunto(int x, int y){
  stroke(255);
  strokeWeight(8);
  noFill();
  point(x,y);
}

void mostrarPuntos(){
 int contador=0;
 while(contador<numPunto){
   Punto p = nuevosPuntos[contador];
    dibujarPunto(p.getX(),p.getY()); 
   contador++;
 }
}

void cargarVectores(){
  nombresActores= new String[6];
  json = loadJSONObject("data.json");
  JSONArray datosPuntos = json.getJSONArray("puntos");
  puntos = new Punto[datosPuntos.size()];
  int contador=0;
  while(contador<datosPuntos.size()){
    JSONObject punto = datosPuntos.getJSONObject(contador); 
    JSONObject pos = punto.getJSONObject("pos");   
    int x = pos.getInt("x");
    int y = pos.getInt("y");
    String nombre = punto.getString("nombre");
    nombresActores[contador]= nombre;
    //print(nombre+" "+x+" "+y+"\n");
    puntos[contador]= new Punto(x,y);
    int contador2=0;
    while(contador2<55){
      String entrada= "d"+(contador2+1);
      double distancia=pos.getDouble(entrada);
      //print(entrada+": "+distancia+"\n");
      vectoresFamosos[contador][contador2]=distancia;
      //print("\""+entrada+"\": "+vectoresFamosos[contador][contador2]+",\n");
      contador2++;
    }
    contador++; 
  }
  //print("dist:"+vectoresFamosos[0][3]);
}

double potencia2(double d){
  return d*d;
}

void definirUbicacionPunto(){
  textAlign(LEFT);
  fill(0);
  color(0);
  stroke(0);
  if(numPunto==0){
    text("Haga Click en el punto central de la línea del cabello.", 10, 20); 
  }else if(numPunto==1){
    text("Haga Click en extremo externo del ojo ubicado en la parte izquierda de la imagen", 10, 20); 
  }else if(numPunto==2){
    text("Haga Click en el extremo interno del ojo ubicado en la parte izquierda de la imagen", 10, 20); 
  }else if(numPunto==3){
    text("Haga Click en el extremo interno del ojo ubicado en la parte derecha de la imagen", 10, 20); 
  }else if(numPunto==4){
    text("Haga Click en el extremo externo del ojo ubicado en la parte derecha de la imagen", 10, 20); 
  }else if(numPunto==5){
    text("Haga Click en el punto central de la base de la nariz", 10, 20); 
  }else if(numPunto==6){
    text("Haga Click en el extremo de la boca ubicado en la parte izquierda de la imagen", 10, 20); 
  }else if(numPunto==7){
    text("Haga Click en el extremo de la boca ubicado en la parte derecha de la imagen", 10, 20); 
  }else if(numPunto==8){
    text("Haga Click en el punto medio de la parte alta del labio superior", 10, 20); 
  }else if(numPunto==9){
    text("Haga Click en el punto medio de la parte baja del labio inferior", 10, 20); 
  }else if(numPunto==10){
    text("Haga Click en el punto medio de la base de la barbilla", 10, 20); 
  }    
}

/*
Determina la distancia del punto p1 al punto p2.
Utiliza diferencia de cuadrados.
*/
double calcularDistancia(Punto p1, Punto p2){ 
  double d=Math.sqrt(potencia2(p1.x - p2.x)+potencia2(p1.y - p2.y));
  return d;
}


double vectoresSemejantes(double[] vBase, double[] vX){
  double maxDifAceptable=0.20;
  int contador=0;
  boolean flag=true;
  double gradoSimilitud=-1;
  
  while(contador<55){
    print("\"d"+(contador+1)+"\": "+vX[contador]+",\n");
    contador++; 
  }
  contador=0;
  while (contador<55 && flag){
    print("comparando"+ vBase[contador] +" contra "+vX[contador]+", con diferencia aceptable de +- "+(vBase[contador]*maxDifAceptable)+"\n");
      if(((vBase[contador]-(vBase[contador]*maxDifAceptable))<vX[contador]) && ((vBase[contador]+(vBase[contador]*maxDifAceptable)>vX[contador]))){
        gradoSimilitud+=abs((float)(vBase[contador]-(vBase[contador]*maxDifAceptable)));
        flag=true;
      }else{
        gradoSimilitud=-1;
        flag=false;
      }
      contador++;
  }
  if(gradoSimilitud>-1){
    gradoSimilitud+=1;
  }
  return gradoSimilitud;
}

void definirPunto(int x, int y){
  if(numPunto<11){
    Punto nuevoPunto = new Punto(x,y);
    nuevosPuntos[numPunto]=nuevoPunto;
    numPunto++;
  }
  if(numPunto==11){
    texto="";
    estado=2;
    numPunto=0;
  }
  print(numPunto);
}
