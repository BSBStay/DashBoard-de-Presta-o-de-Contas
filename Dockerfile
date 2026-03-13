# ============================================================
# BSB.STAY — Dockerfile para Render.com
# Base: rocker/shiny (Shiny Server + R já configurados)
# ============================================================

FROM rocker/shiny:4.3.3

# Dependências de sistema necessárias para alguns pacotes R
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libsodium-dev \
    && rm -rf /var/lib/apt/lists/*

# Instalar pacotes R do app
RUN R -e "install.packages(c( \
    'dplyr', \
    'tidyr', \
    'lubridate', \
    'readxl', \
    'janitor', \
    'plotly', \
    'DT', \
    'DBI', \
    'RSQLite', \
    'shinycssloaders', \
    'stringr' \
  ), repos='https://packagemanager.posit.co/cran/latest', Ncpus=2)"

# Criar diretório de cache de dados (persistido em runtime)
RUN mkdir -p /srv/shiny-server/bsbstay/data/cache \
    && mkdir -p /srv/shiny-server/bsbstay/data/raw \
    && chmod -R 777 /srv/shiny-server/bsbstay/data

# Copiar arquivos do app
COPY app.R          /srv/shiny-server/bsbstay/app.R
COPY R/gdrive_public.R  /srv/shiny-server/bsbstay/R/gdrive_public.R

# Configuração do Shiny Server (aumenta timeout e desativa logs verbosos)
RUN echo '\
server { \n\
  listen 3838; \n\
  location /bsbstay { \n\
    app_dir /srv/shiny-server/bsbstay; \n\
    log_dir /var/log/shiny-server; \n\
    directory_index off; \n\
  } \n\
  location / { \n\
    app_dir /srv/shiny-server/bsbstay; \n\
    log_dir /var/log/shiny-server; \n\
  } \n\
}' > /etc/shiny-server/shiny-server.conf

EXPOSE 3838

CMD ["/usr/bin/shiny-server"]
