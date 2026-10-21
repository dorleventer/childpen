# Compare two golden-master snapshots (see dev/snapshot_all.R).
#
#   Rscript dev/snapshot_compare.R <baseline.rds> <new.rds>
#
# Prints GATE: PASS when every value in the baseline is identical() in the new snapshot, and
# GATE: FAIL (exit status 1) otherwise.
#   * Lists are compared element by element (new elements allowed, missing ones fail).
#   * Result data.frames (they have a `method` column) are matched row by row on their key
#     columns; every baseline column must be identical on the matched rows. New rows and new
#     columns are allowed and listed.
#   * Other data.frames / data.tables (simulated data, IF scores) are compared column by column
#     on the baseline's columns, in the baseline's row order.
#   * Attributes of data.frames (if_scores, if_data, n_obs, ...) are compared the same way.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) stop("usage: Rscript dev/snapshot_compare.R <baseline.rds> <new.rds>")
base <- readRDS(args[1]); new <- readRDS(args[2])

key_cols <- c("d", "dp", "a", "event_time", "estimand", "method", "agg_type")
fails <- character(0); notes <- character(0)
fail <- function(path, msg) fails <<- c(fails, sprintf("%s: %s", path, msg))
note <- function(path, msg) notes <<- c(notes, sprintf("%s: %s", path, msg))

cmp_df <- function(b, n, path) {
  b <- as.data.frame(b); n <- as.data.frame(n)
  miss <- setdiff(names(b), names(n))
  if (length(miss)) fail(path, paste("missing columns:", paste(miss, collapse = ", ")))
  extra <- setdiff(names(n), names(b))
  if (length(extra)) note(path, paste("new columns:", paste(extra, collapse = ", ")))
  cols <- intersect(names(b), names(n))
  if ("method" %in% names(b)) {
    k <- intersect(key_cols, names(b))
    kb <- do.call(paste, c(b[k], sep = "|")); kn <- do.call(paste, c(n[k], sep = "|"))
    if (anyDuplicated(kb)) fail(path, "duplicate keys in baseline")
    idx <- match(kb, kn)
    if (anyNA(idx)) fail(path, sprintf("%d baseline rows missing", sum(is.na(idx))))
    if (length(setdiff(kn, kb))) note(path, sprintf("%d new rows", length(setdiff(kn, kb))))
    ok <- !is.na(idx)
    for (cl in setdiff(cols, k)) {
      if (!identical(b[[cl]][ok], n[[cl]][idx[ok]])) fail(path, paste("column changed:", cl))
    }
  } else {
    if (nrow(b) != nrow(n)) { fail(path, sprintf("rows %d -> %d", nrow(b), nrow(n))); return() }
    for (cl in cols) if (!identical(b[[cl]], n[[cl]])) fail(path, paste("column changed:", cl))
  }
}

cmp <- function(b, n, path) {
  if (is.data.frame(b)) {
    if (!is.data.frame(n)) { fail(path, "no longer a data.frame"); return() }
    cmp_df(b, n, path)
    skip <- c("names", "row.names", "class", ".internal.selfref", "sorted", "index")
    for (at in setdiff(names(attributes(b)), skip)) {
      if (is.null(attr(n, at))) fail(path, paste("missing attribute:", at))
      else cmp(attr(b, at), attr(n, at), paste0(path, "@", at))
    }
  } else if (is.list(b)) {
    for (nm in names(b)) {
      if (!nm %in% names(n)) fail(path, paste("missing element:", nm))
      else cmp(b[[nm]], n[[nm]], paste0(path, "$", nm))
    }
    extra <- setdiff(names(n), names(b))
    if (length(extra)) note(path, paste("new elements:", paste(extra, collapse = ", ")))
  } else if (!identical(b, n)) fail(path, "value changed")
}

cmp(base, new, "snap")
if (length(notes)) cat("Additions (allowed):\n", paste0("  ", notes, "\n"), sep = "")
if (length(fails)) {
  cat("Differences:\n", paste0("  ", fails, "\n"), sep = "")
  cat("GATE: FAIL\n"); quit(status = 1)
}
cat("GATE: PASS\n")
