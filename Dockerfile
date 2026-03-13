# BSB.STAY — Dockerfile para Render.com
FROM rocker/shiny:4.3.3
 
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev libssl-dev libxml2-dev \
    && rm -rf /var/lib/apt/lists/*
 
RUN R -e "install.packages(c( \
    'dplyr','tidyr','lubridate','readxl','janitor', \
    'plotly','DT','DBI','RSQLite','shinycssloaders','stringr' \
  ), repos='https://packagemanager.posit.co/cran/latest', Ncpus=2)"
 
RUN mkdir -p /srv/shiny-server/app/data/cache \
    && chmod -R 777 /srv/shiny-server/app
 
COPY app.R            /srv/shiny-server/app/app.R
COPY gdrive_public.R  /srv/shiny-server/app/gdrive_public.R
 
RUN printf 'run_as shiny;\nserver {\n  listen 3838;\n  location / {\n    app_dir /srv/shiny-server/app;\n    log_dir /var/log/shiny-server;\n  }\n}\n' \
    > /etc/shiny-server/shiny-server.conf
 
EXPOSE 3838
CMD ["/usr/bin/shiny-server"]
 
