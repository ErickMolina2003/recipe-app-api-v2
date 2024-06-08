# esta es la imagen inicial o imagen base para python usando alpine de docker hub python
FROM python:3.9-alpine3.13
# esta es quien mantiene el docker
LABEL maintainer="erick"

# esto hace que las respuestas de python se hagan print inmediatamente sin que docker les haga buffer
ENV PYTHONUNBUFFERED 1

# 1. copiar los requerimientos de la app y ponerlos en la imagen, 2. copiar el directorio app y ponerlo en el docker 
# 3. inicializar el directorio de trabajo de la imagen en /app y alli se aplican los comandos, 4. expongo el puerto 8000 
COPY ./requirements.txt /tmp/requirements.txt
COPY ./requirements.dev.txt /tmp/requirements.dev.txt
COPY ./app /app
WORKDIR /app
EXPOSE 8000


# corre un comando en la imagen alpine cuando construimos la imagen
# 1. python -m venv crea un ambiente virtual
# 2. especificamos el path de nuestro ambiente virtual y instalar pip para manejar dependencias, el node de python
     # 2.1 para agregar la base de datos, agregamos el apk de postgresql-client para que corra la base de datos
    # 2.2 luego agregamos otro apk pero en un ambiente virtual y en una carpeta llamada .tmp-build-deps y en esta
        # carpeta instalamos dependencias para la base ed datos (build base, musl, etc)
# 3. despues instalamos nuestros requirements, los cuales copiamos con COPY ./requirements.txt y pusimos en /tmp/requirements.txt
    # 3.2 instalamos de la misma forma los requirements pero de dev pero usando un condicional shell solo si Dev=true
# 4. removemos el directorio /tmp para no tener dependencias extras al crear la imagen
    # 4.1 y removemos tambien el directorio del apk tmp-build-deps que se uso para instalar dependencias de base de datos
# 5. agregamos un usuario en nuestra imagen para no tener que usar el root user porque no es buena practica por seguridad
# 5.1 agregamos directorios /vol/web/media y /static para almacenar imagenes y le asignamos el usuario django user con chown y los permisos
    # con chmod
# 6. ENV actualiza las env variables dentro de la imagen y actualiza el path env variables, para que cuando corramos
#     comandos, sepan donde estan las env variables de la imagen

# ARG => cuando usamos este dockerfile mediante docker-compose este ARG se va a sobreescribir con FALSE debido al args
    # del dockercompose, pero si usamos este dockerfile con otra cosa, siempre va estar con DEV=false
ARG DEV=false
RUN python -m venv /py && \
    /py/bin/pip install --upgrade pip && \
    apk add --update --no-cache postgresql-client jpeg-dev && \
    apk add --update --no-cache --virtual .tmp-build-deps \
        build-base postgresql-dev musl-dev zlib zlib-dev && \
    /py/bin/pip install -r /tmp/requirements.txt && \
    if [ $DEV = "true" ]; \
        then /py/bin/pip install -r /tmp/requirements.dev.txt ; \
    fi && \
    rm -rf /tmp && \
    apk del .tmp-build-deps && \
    adduser \ 
        --disabled-password \
        --no-create-home \
        django-user && \
    mkdir -p /vol/web/media && \
    mkdir -p /vol/web/static && \
    chown -R django-user:django-user /vol && \
    chmod -R 755 /vol

ENV PATH="/py/bin:$PATH"

# 1. Esta debe ser la ultima linea de dockerfile y especifica el usuario al que nos estamos cambiando,
    # antes de este comando todo se ejecuta con el usuario root y los contenedores van a usar este usuario cambiado
USER django-user
