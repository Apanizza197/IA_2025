Tarea 3:
Dentro de la carpeta infra se encuentra todo el código de terraform usado para desplegar la infraestructura en aws. particularmente los archivos dentro de la carpeta lambda_scripts contienen las funciones de carga de datos a la bdd (api_post_data.py) y de recibir mensaje y responder con la conexiona gemini y el rag (api_post_message.py)


Tarea 1:
esp files: Código fuente para la ESP32. 
  sketch_v3.ino tiene el codigo que lee los sensores y guarda los datos en la placa. 
  print_data.ino tiene el código para leer el archivo donde se guardaron los datos en la placa.

sensor_log_27_04.log: Datos crudos generados por la ESP32.

preprocess_txt.ipynb: Preprocesa los datos de sensor_log_27_04.log usando start_times.csv para crear datos_planta.csv.

start_times.csv: Contiene las fechas de encendido de la placa y el estado de la planta.

datos_planta.csv: Datos procesados listos para análisis.

analisis.ipynb: Análisis de los datos procesados.
