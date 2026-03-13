# ============================================================
# BSBStay — DIAGNÓSTICO v2
# Substitua o app.R por este arquivo, faça push.
# O erro exato vai aparecer no browser.
# ============================================================
library(shiny)

ETAPAS <- list()

registrar <- function(nome, expr) {
  resultado <- tryCatch({
    val <- expr
    list(ok=TRUE, nome=nome, val=if(is.character(val)) val else "OK")
  }, error = function(e) {
    list(ok=FALSE, nome=nome, val=e$message)
  }, warning = function(w) {
    list(ok=TRUE, nome=nome, val=paste("AVISO:", w$message))
  })
  ETAPAS[[length(ETAPAS)+1]] <<- resultado
  resultado$ok
}

# ── Etapa 1: Pacotes ──
pkgs <- c("shiny","dplyr","tidyr","lubridate","readxl",
          "janitor","plotly","DT","DBI","RSQLite","shinycssloaders","stringr")
for (p in pkgs) {
  registrar(paste("pkg:", p), requireNamespace(p, quietly=TRUE))
}

# ── Etapa 2: PROJ_ROOT ──
registrar("PROJ_ROOT detectado", {
  cands <- c("/srv/shiny-server/app", getwd())
  found <- cands[file.exists(file.path(cands, "gdrive_public.R"))]
  PROJ_ROOT <<- if (length(found) > 0) found[1] else cands[1]
  PROJ_ROOT
})

# ── Etapa 3: Arquivos no diretório ──
registrar("arquivos no PROJ_ROOT", {
  paste(list.files(PROJ_ROOT, all.files=TRUE), collapse=" | ")
})

# ── Etapa 4: gdrive_public.R existe ──
registrar("gdrive_public.R existe", {
  path <- file.path(PROJ_ROOT, "gdrive_public.R")
  if (!file.exists(path)) stop("NÃO ENCONTRADO em: ", path)
  paste("Encontrado:", path, "— tamanho:", file.size(path), "bytes")
})

# ── Etapa 5: Permissão de escrita em /tmp ──
registrar("escrita em /tmp", {
  writeLines("teste", "/tmp/bsbstay_test.txt")
  "OK — /tmp tem escrita"
})

# ── Etapa 6: source gdrive_public.R ──
registrar("source(gdrive_public.R)", {
  source(file.path(PROJ_ROOT, "gdrive_public.R"), local=FALSE)
  "source() concluído sem erros"
})

# ── Etapa 7: DRIVE_FILE_ID definido ──
registrar("DRIVE_FILE_ID", {
  if (!exists("DRIVE_FILE_ID")) stop("variável não definida após source()")
  paste("OK:", DRIVE_FILE_ID)
})

# ── Etapa 8: CACHE_XLSX e SQLITE_PATH ──
registrar("CACHE_XLSX path", {
  if (!exists("CACHE_XLSX")) stop("CACHE_XLSX não definido")
  paste("OK:", CACHE_XLSX)
})
registrar("SQLITE_PATH path", {
  if (!exists("SQLITE_PATH")) stop("SQLITE_PATH não definido")
  paste("OK:", SQLITE_PATH)
})

# ── Etapa 9: Criar diretório de cache ──
registrar("criar dir cache", {
  cache_dir <- dirname(SQLITE_PATH)
  dir.create(cache_dir, recursive=TRUE, showWarnings=FALSE)
  if (!dir.exists(cache_dir)) stop("falhou criar: ", cache_dir)
  paste("OK:", cache_dir)
})

# ── Etapa 10: SQLite conecta ──
registrar("SQLite conecta", {
  con <- DBI::dbConnect(RSQLite::SQLite(), SQLITE_PATH)
  DBI::dbDisconnect(con)
  paste("OK:", SQLITE_PATH)
})

# ── Etapa 11: Download Google Drive ──
registrar("download Google Drive", {
  dl <- baixar_db_master_publico(forcar=TRUE)
  if (!dl$ok) stop(dl$msg)
  paste("OK — source:", dl$source)
})

# ── Etapa 12: Ler xlsx ──
registrar("ler xlsx", {
  if (!file.exists(CACHE_XLSX)) stop("xlsx não existe: ", CACHE_XLSX)
  sheets <- readxl::excel_sheets(CACHE_XLSX)
  paste("Abas:", paste(sheets, collapse=", "))
})

# ── UI ──────────────────────────────────────────────────────
ui <- fluidPage(
  tags$head(tags$style("
    body { font-family: monospace; background: #0f1117; color: #e0e0e0; padding: 30px; }
    h2 { color: #60a5fa; }
    .ok  { color: #4ade80; display: block; padding: 4px 0; }
    .err { color: #f87171; display: block; padding: 4px 0; font-weight: bold; }
    .detail { color: #94a3b8; font-size: 12px; margin-left: 20px; display: block; }
    pre { background: #1a1a2e; padding: 15px; border-radius: 8px; }
  ")),
  h2("🔍 BSBStay — Diagnóstico v2"),
  tags$hr(),
  uiOutput("resultado")
)

server <- function(input, output, session) {
  output$resultado <- renderUI({
    items <- lapply(ETAPAS, function(e) {
      tags$div(
        tags$span(class=if(e$ok) "ok" else "err",
                  paste0(if(e$ok) "✅ " else "❌ ", e$nome)),
        tags$span(class="detail", e$val)
      )
    })
    
    erros <- Filter(function(e) !e$ok, ETAPAS)
    resumo <- if (length(erros) == 0) {
      tags$p(style="color:#4ade80; font-size:18px; margin-top:20px",
             "✅ Todas as etapas OK!")
    } else {
      tags$div(
        tags$hr(),
        tags$h3(style="color:#f87171", paste("❌", length(erros), "erro(s) encontrado(s):")),
        tags$pre(style="color:#f87171; background:#1f1020",
                 paste(sapply(erros, function(e) paste0("• ", e$nome, ":\n  ", e$val)),
                       collapse="\n\n"))
      )
    }
    
    tagList(do.call(tagList, items), resumo)
  })
}

shinyApp(ui, server)
