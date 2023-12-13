FROM rocker/shiny:latest

# Copier les fichiers de l'application Shiny dans le conteneur
COPY . /srv/shiny-server/tamaR

# Installer les paquets R nécessaires (remplacer 'package1 package2' par vos paquets)
RUN R -e "install.packages(c('png', 'shiny', 'R.utils'), repos='https://cloud.r-project.org/')"

WORKDIR /srv/shiny-server/tamaR

RUN Rscript /srv/shiny-server/tamaR/src/TamaRomConvert.r

RUN R CMD build .
RUN R CMD INSTALL tamaR_1.0.0.tar.gz

# Exposer le port (3838 est le port par défaut de Shiny Server)
EXPOSE 1996

COPY shiny-server.conf /etc/shiny-server/shiny-server.conf

# Lancer Shiny Server
CMD ["/usr/bin/shiny-server"]

