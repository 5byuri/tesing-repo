package documentationMerged

import future.keywords.contains
import future.keywords.if
import future.keywords.in

productionRepo := data.production_repo
documentationRepo := data.documentation_repo
pullRequestTitle := data.pull_request_title

# ---------- helpers ----------

is_pr(x) if {
  object.get(x, "pull_request", null) != null
}

# (optional) merged check, falls du NUR gemergte docs-PRs akzeptieren willst
is_merged_pr(x) if {
  is_pr(x)
  object.get(x.pull_request, "merged_at", null) != null
}

# ---------- existence checks ----------

# "Gibt es den aktuellen PR überhaupt im productionRepo?"
# (Optional – aber hilft gegen falsche Inputs / falsches Repo)
production_pr_exists if {
  some x in input
  x.repository == productionRepo
  is_pr(x)
  x.title == pullRequestTitle
}

# "Gibt es einen PR im documentationRepo mit exakt gleichem Titel?"
# Variante A: irgendein PR (open/closed egal)
docs_pr_exists_with_title if {
  some x in input
  x.repository == documentationRepo
  is_pr(x)
  x.title == pullRequestTitle
}

# Variante B: NUR gemergte PRs zählen (empfohlen, wenn es ein Gate sein soll)
docs_merged_pr_exists_with_title if {
  some x in input
  x.repository == documentationRepo
  is_merged_pr(x)
  x.title == pullRequestTitle
}

# ---------- output ----------

# Wenn du "docs PR existiert (egal ob merged)" willst:
# failure_msg contains msg if {
#   production_pr_exists
#   not docs_pr_exists_with_title
#   msg := sprintf("Kein PR im Doku-Repo '%v' mit dem Titel '%v' gefunden (Production-Repo: '%v').", [documentationRepo, pullRequestTitle, productionRepo])
# }

# Wenn du "docs PR muss GEMERGED sein" willst (typischer Gate-Fall):
failure_msg contains msg if {
  production_pr_exists
  not docs_merged_pr_exists_with_title

  msg := sprintf(
    "Dokumentations-PR fehlt: Für den Production-PR-Titel '%v' (%v) existiert kein GEMERGTER PR mit gleichem Titel im Doku-Repo %v.",
    [pullRequestTitle, productionRepo, documentationRepo]
  )
}

# Optional: wenn production_pr_exists nicht gefunden wird, kannst du auch failen:
failure_msg contains msg if {
  not production_pr_exists
  msg := sprintf(
    "Production-PR '%v' wurde im Repo '%v' im Input nicht gefunden (kann auf falsches Repo/Fetch/Attestation hindeuten).",
    [pullRequestTitle, productionRepo]
  )
}

