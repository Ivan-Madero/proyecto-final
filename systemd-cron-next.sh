#! /bin/bash
# Script para la instalacion de 'systemd-cron-next'.
# Requisitos: tener instalado paquete 'cargo'. 

git clone https://github.com/systemd-cron/systemd-cron-next.git

cd systemd-cron-next/

# Usando los por defecto
./configure --runparts=/usr/bin/run-parts \
			--enable-boot=yes \
			--enable-minutely=no \
			--enable-hourly=yes \
			--enable-daily=yes \
			--enable-weekly=yes \
			--enable-monthly=yes
make

make build

make install
