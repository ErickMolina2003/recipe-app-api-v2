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
# 3. despues instalamos nuestros requirements, los cuales copiamos con COPY ./requirements.txt y pusimos en /tmp/requirements.txt
    # 3.2 instalamos de la misma forma los requirements pero de dev pero usando un condicional shell solo si Dev=true
# 4. removemos el directorio /tmp para no tener dependencias extras al crear la imagen
# 5. agregamos un usuario en nuestra imagen para no tener que usar el root user porque no es buena practica por seguridad
# 6. ENV actualiza las env variables dentro de la imagen y actualiza el path env variables, para que cuando corramos
#     comandos, sepan donde estan las env variables de la imagen

# ARG => cuando usamos este dockerfile mediante docker-compose este ARG se va a sobreescribir con FALSE debido al args
    # del dockercompose, pero si usamos este dockerfile con otra cosa, siempre va estar con DEV=false
ARG DEV=false
RUN python -m venv /py && \
    /py/bin/pip install --upgrade pip && \
    /py/bin/pip install -r /tmp/requirements.txt && \
    if [ $DEV = "true" ]; \
        then /py/bin/pip install -r /tmp/requirements.dev.txt ; \
    fi && \
    rm -rf /tmp && \
    adduser \ 
        --disabled-password \
        --no-create-home \
        django-user

ENV PATH="/py/bin:$PATH"

# 1. Esta debe ser la ultima linea de dockerfile y especifica el usuario al que nos estamos cambiando,
    # antes de este comando todo se ejecuta con el usuario root y los contenedores van a usar este usuario cambiado
USER django-user
