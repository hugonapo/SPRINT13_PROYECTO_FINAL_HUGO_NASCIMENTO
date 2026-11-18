# Salud mental en el sector tecnológico · De una encuesta larga a 7 preguntas

**Autor:** Hugo Nascimento · Proyecto final (Tasca S13.01) · Data Analytics · IT Academy (Barcelona Activa)
**Repositorio:** https://github.com/hugonapo/SPRINT13_PROYECTO_FINAL_HUGO_NASCIMENTO

## De qué va el proyecto

Mi idea inicial era anticiparme a las bajas por salud mental en una empresa. Pero los datos de bajas son datos de salud, y el RGPD prohíbe tratarlos sin consentimiento explícito (art. 9.1). Por eso cambié el enfoque: **si no puedo usar datos de salud, construyo una herramienta que no los necesite.**

Parto de una encuesta pública y muy larga sobre salud mental en el sector tech (OSMI) y la **destilo** con un Random Forest hasta quedarme con **7 preguntas que no piden ningún dato de salud** y que permiten saber, por equipos, dónde la gente callaría su problema.

**Mi pregunta:** ¿Qué pesa más para que un profesional tech hable de su salud mental en el trabajo, y cómo puede saberlo una empresa sin ser invasiva?

- **Pregunta central (19):** ¿te sentirías cómodo hablando de tu salud mental con tu supervisor?
- **Pregunta de contraste (33):** ¿tienes ahora un trastorno de salud mental? ¿Pesan las mismas cosas para tenerlo que para hablarlo?

## Resultados principales

- **42 de cada 100** profesionales dicen tener un trastorno ahora, y el **52 %** de ellos nunca lo ha contado en su empresa.
- Para **tener** un trastorno pesa la salud personal (81 % de la importancia del modelo 33). Para **hablarlo** pesan la empresa y el clima (91 % del modelo 19).
- El modelo 19 (Random Forest, 500 árboles) acierta con datos que no ha visto: **AUC 0,91**, accuracy 83 % y detecta al **78 %** de quienes callarían.
- Con **7 preguntas sin datos de salud** (57, 81, 28, 17, 65, 85 y 11) el modelo acierta igual que con las 48: AUC 0,91. Conserva el 98 % del acierto con el 15 % de las preguntas.
- Hablar no basta: contarlo no reduce el impacto en el trabajo (74 % frente a 78 %), pero **tratarse sí** (del 76 % al 11 %).

## Los datos

He utilizado la encuesta *OSMI Mental Health in Tech Survey* (Open Sourcing Mental Health) de 2014, 2016, 2017, 2018 y 2019: 4.218 profesionales del sector tech, 105 preguntas y 236.898 respuestas.

La he descargado de Kaggle en la versión SQLite publicada por Anthony Inthavong (licencia CC BY-SA 4.0): https://www.kaggle.com/datasets/anth7310/mental-health-in-the-tech-industry

La base original tenía 3 tablas y todo en inglés. He traducido preguntas y respuestas al español y la he normalizado en un modelo relacional de 7 tablas (`encuestas`, `temas`, `preguntas`, `paises`, `tamanos_empresa`, `personas` y `respuestas`) con claves primarias y foráneas. El diagrama está en `04_figuras/00_modelo_relacional.png`.

## Herramientas

SQL (MySQL y SQLite) · Python (pandas, NumPy, matplotlib, seaborn, SciPy, scikit-learn) · Google Colab · Visual Studio Code · Power BI

## Qué hay en cada carpeta

```
01_datos/
  originales/mental_health.sqlite             base de datos original de Kaggle (3 tablas), sin tocar
  auxiliares/traduccion_*.csv                 mis traducciones de las preguntas y las respuestas
  auxiliares/catalogo_preguntas.pdf / .csv    las 105 preguntas con sus años, tipo de respuesta y opciones
  auxiliares/preguntas_2016_2019_bloques.csv  preguntas de 2016-2019 agrupadas en bloques
  auxiliares/tema_de_cada_pregunta.csv        el tema (de los 8) al que asigno cada pregunta del modelo
  procesados/*.csv                            las 7 tablas limpias
  procesados/salud_mental_tech.db             la misma base en SQLite, para los notebooks
02_notebooks/
  01_limpieza_y_modelo.ipynb                  revisión de la base original, limpieza y modelo de 7 tablas
  02_analisis_exploratorio.ipynb              EDA: nulos por año, valores atípicos, distribuciones y relaciones
  03_random_forest.ipynb                      Random Forest paso a paso, destilación a 7 preguntas y gráficos del modelo
  04_graficos_presentacion.ipynb              gráficos descriptivos de la presentación, calculados desde la base de datos
03_sql/
  01_crear_base_datos.sql                     crea la base salud_mental_tech en MySQL con todos los datos
  02_consultas.sql                            las consultas de análisis
  03_capturas_consultas.pdf                   capturas de MySQL Workbench de cada consulta
04_figuras/                                   los gráficos que generan los notebooks (los de la presentación llevan el prefijo p_)
05_powerbi/
  salud_mental_tech.pbix                      el dashboard (4 páginas)
  dashboard_powerbi.pdf                       el dashboard exportado a PDF
  datos/                                      los CSV que carga el dashboard
  medidas_dax.pdf / .txt                      las fórmulas DAX, explicadas una a una
  tema_salud_mental_tech.json                 el tema de colores
06_informe/
  informe.pdf                                 el informe del proyecto (4 páginas)
07_presentacion/
  salud_mental_tech_presentacion.pdf / .pptx  la presentación final
requirements.txt                              las librerías de Python
```

## Cómo reproducirlo

1. **MySQL Workbench:** Server > Data Import > Import from Self-Contained File > `03_sql/01_crear_base_datos.sql` > Start Import. Al final el script enseña cuántas filas tiene cada tabla (en `respuestas` tienen que salir 236.898).
2. Abro `03_sql/02_consultas.sql` y ejecuto cada consulta con el cursor dentro y Ctrl+Enter.
3. **Python:** `pip install -r requirements.txt` y ejecuto los notebooks de `02_notebooks/` en orden (01 → 04). El 03 tarda unos minutos, porque entrena varios Random Forest.
4. **Power BI:** abro `05_powerbi/salud_mental_tech.pbix`. Si los datos no cargan, en *Transformar datos > Configuración de origen de datos* cambio la ruta de los CSV a la carpeta `05_powerbi/datos/` de este repositorio.

Si Windows bloquea alguna librería (a mí me pasó con SciPy por Smart App Control), los notebooks se pueden ejecutar en Google Colab: subo la carpeta del repositorio a la raíz de Google Drive y cada notebook tiene al principio una celda que conecta con Drive. Fuera de Colab esa celda no hace nada.

## Limitaciones

- Muestra voluntaria: 73 % hombres y 62 % de EE. UU. Los resultados describen a este perfil, no a todo el sector.
- Datos de 2014 a 2019, antes de la pandemia.
- Son respuestas de muchas empresas distintas; lo ideal sería tener los datos de una sola empresa.
- Lo que cada persona declara, no diagnósticos médicos.
- El modelo dice qué preguntas ayudan a predecir, no qué causa qué.
