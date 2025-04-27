esp files: Código fuente para la ESP32. 
  sketch_v3.ino tiene el codigo que lee los sensores y guarda los datos en la placa. 
  print_data.ino tiene el código para leer el archivo donde se guardaron los datos en la placa.

sensor_log_27_04.log: Datos crudos generados por la ESP32.

preprocess_txt.ipynb: Preprocesa los datos de sensor_log_27_04.log usando start_times.csv para crear datos_planta.csv.

start_times.csv: Contiene las fechas de encendido de la placa y el estado de la planta.

datos_planta.csv: Datos procesados listos para análisis.

analisis.ipynb: Análisis de los datos procesados.
