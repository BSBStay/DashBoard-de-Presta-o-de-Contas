#!/usr/bin/env Rscript
# ============================================================
# setup.R — Configuração inicial do BSBStay Shiny App
# Execute uma vez antes de iniciar o app:  source("setup.R")
# ============================================================

cat("\n═══════════════════════════════════════════════════\n")
cat("  BSB.STAY — Setup de integração Google Drive\n")
cat("═══════════════════════════════════════════════════\n\n")

# ── 1. Instala pacotes ────────────────────────────────────────
pkgs <- c(
  "shiny", "dplyr", "tidyr", "lubridate", "readxl",
  "janitor", "plotly", "DT", "DBI", "RSQLite",
  "shinycssloaders", "stringr"
)

miss <- pkgs[!pkgs %in% installed.packages()[, "Package"]]
if (length(miss) > 0) {
  cat(sprintf("Instalando %d pacote(s): %s\n", length(miss), paste(miss, collapse = ", ")))
  install.packages(miss)
} else {
  cat("✓ Todos os pacotes já instalados.\n")
}

# ── 2. Cria estrutura de diretórios ───────────────────────────
dirs <- c("data/cache", "data/raw", "R", "config")
for (d in dirs) {
  if (!dir.exists(d)) {
    dir.create(d, recursive = TRUE)
    cat(sprintf("  Criado: %s/\n", d))
  }
}
cat("✓ Estrutura de diretórios OK.\n")

# ── 3. Testa conectividade com o Google Drive ─────────────────
cat("\nTestando acesso ao Google Drive público...\n")
DRIVE_FOLDER_ID <- "1753AZxwmyyWYS2oYQPLeMHIz5gM8bscb"
test_url <- paste0("https://drive.google.com/drive/folders/", DRIVE_FOLDER_ID)

result <- tryCatch({
  tmp <- tempfile(); on.exit(unlink(tmp))
  old_to <- getOption("timeout"); options(timeout = 15)
  on.exit(options(timeout = old_to), add = TRUE)
  st <- utils::download.file(test_url, tmp, quiet = TRUE, method = "libcurl")
  st == 0
}, error = function(e) FALSE)

if (result) {
  cat("✓ Google Drive acessível.\n")
} else {
  cat("⚠ Não foi possível acessar o Google Drive.\n")
  cat("  Certifique-se de que a pasta está compartilhada publicamente.\n")
  cat("  O app usará dados em cache se disponíveis.\n")
}

# ── 4. Informações sobre o arquivo do Drive ───────────────────
cat("\n─────────────────────────────────────────────────\n")
cat("Configuração:\n")
cat(sprintf("  Pasta Drive: https://drive.google.com/drive/folders/%s\n", DRIVE_FOLDER_ID))
cat(sprintf("  Cache xlsx:  data/cache/db_master_drive.xlsx\n"))
cat(sprintf("  SQLite:      data/cache/bsbstay.sqlite\n"))
cat(sprintf("  Cache TTL:   6 horas\n"))
cat("\n")

# ── 5. Instruções de uso ──────────────────────────────────────
cat("Para garantir que o app funcione:\n\n")
cat("  1. Abra a pasta do Drive no link acima\n")
cat("  2. Certifique-se de que está compartilhada como:\n")
cat("     'Qualquer pessoa com o link pode visualizar'\n")
cat("  3. O arquivo '[DB] BSBStay_VF.xlsx' deve estar\n")
cat("     visível na pasta raiz ou subpasta de 2025\n\n")
cat("Para iniciar o app:\n")
cat("  shiny::runApp('.')\n\n")
cat("Para diagnosticar problemas de conexão com o Drive:\n")
cat("  source('R/gdrive_public.R'); diagnostico_drive()\n\n")
cat("Se o Drive não estiver acessível, carregue o arquivo manualmente:\n")
cat("  source('R/gdrive_public.R')\n")
cat("  carregar_xlsx_local('caminho/para/[DB] BSBStay_VF.xlsx')\n\n")
cat("Para forçar re-download do Drive:\n")
cat("  # No app, clique em '↻ Atualizar dados'\n")
cat("  # Ou no console:\n")
cat("  source('R/gdrive_public.R')\n")
cat("  carregar_dados_app(forcar_dl = TRUE)\n\n")
cat("═══════════════════════════════════════════════════\n")
cat("  Setup concluído! Execute: shiny::runApp('.')\n")
cat("═══════════════════════════════════════════════════\n\n")
