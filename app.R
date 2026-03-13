# ============================================================
# BSBStay — MODO DIAGNÓSTICO
# Cole este conteúdo no app.R, faça push, abra o site.
# O erro real vai aparecer no browser.
# Depois substitua pelo app.R original corrigido.
# ============================================================
library(shiny)

DIAG <- local({
  msgs <- character(0)
  erros <- character(0)

  # 1. Pacotes
  pkgs <- c("shiny","dplyr","tidyr","lubridate","readxl",
            "janitor","plotly","DT","DBI","RSQLite",
            "shinycssloaders","stringr")
  for (p in pkgs) {
    ok <- requireNamespace(p, quietly = TRUE)
    msgs <- c(msgs, paste0(if(ok) "✅" else "❌", " ", p))
    if (!ok) erros <- c(erros, paste("Pacote ausente:", p))
  }

  # 2. PROJ_ROOT
  proj <- tryCatch({
    candidates <- c("/srv/shiny-server/app", getwd())
    found <- candidates[file.exists(file.path(candidates, "gdrive_public.R"))]
    if (length(found) > 0) found[1] else candidates[1]
  }, error = function(e) paste("ERRO PROJ_ROOT:", e$message))
  msgs <- c(msgs, paste("📁 PROJ_ROOT:", proj))

  # 3. gdrive_public.R existe?
  gf <- file.path(proj, "gdrive_public.R")
  if (file.exists(gf)) {
    msgs <- c(msgs, paste("✅ gdrive_public.R encontrado em:", gf))
    # 4. Tentar fazer source
    src_err <- tryCatch({
      source(gf, local = TRUE)
      NULL
    }, error = function(e) e$message)
    if (!is.null(src_err)) {
      msgs  <- c(msgs,  paste("❌ Erro ao carregar gdrive_public.R"))
      erros <- c(erros, paste("source() falhou:", src_err))
    } else {
      msgs <- c(msgs, "✅ gdrive_public.R carregado sem erros")
    }
  } else {
    msgs  <- c(msgs,  paste("❌ gdrive_public.R NÃO encontrado"))
    erros <- c(erros, paste("Arquivo não existe:", gf))
    msgs  <- c(msgs,  paste("📂 Arquivos em /srv/shiny-server/app:",
                            paste(list.files("/srv/shiny-server/app"), collapse=", ")))
  }

  list(msgs = msgs, erros = erros)
})

ui <- fluidPage(
  tags$head(tags$style("
    body { font-family: monospace; background: #0f1117; color: #e0e0e0; padding: 30px; }
    h2   { color: #60a5fa; }
    .ok  { color: #4ade80; }
    .err { color: #f87171; background: #1f1f2e; padding: 10px; border-radius: 6px; margin-top: 6px; }
    pre  { background: #1a1a2e; padding: 15px; border-radius: 8px; font-size: 13px; }
  ")),
  h2("🔍 BSBStay — Diagnóstico de Inicialização"),
  tags$hr(),
  h4("Status dos componentes:"),
  pre(paste(DIAG$msgs, collapse = "\n")),
  if (length(DIAG$erros) > 0) {
    tagList(
      h4(style="color:#f87171", "❌ Erros encontrados:"),
      tags$div(class="err", pre(paste(DIAG$erros, collapse = "\n")))
    )
  } else {
    tags$p(class="ok", "✅ Todos os componentes OK — o problema pode estar em outro lugar.")
  }
)

server <- function(input, output, session) {}

shinyApp(ui, server)
