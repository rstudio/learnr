# ---- pkgdown::deploy_site_github() ----
#
# Follows the steps of deploy_site_github() but renders into
# `preview/pr#` of `gh-pages` branch.

# Pull gh-pages branch
callr::run("git", c("remote", "set-branches", "--add", "origin", "gh-pages"), echo_cmd = TRUE)
callr::run("git", c("fetch", "origin", "gh-pages"), echo_cmd = TRUE)

local({
  # Setup worktree in tempdir
  dest_dir <- fs::dir_create(fs::file_temp())
  on.exit(unlink(dest_dir, recursive = TRUE), add = TRUE)

  callr::run("git", c("worktree", "add", "--track", "-B", "gh-pages", dest_dir, "origin/gh-pages"), echo_cmd = TRUE)
  on.exit(add = TRUE, {
    callr::run("git", c("worktree", "remove", dest_dir), echo_cmd = TRUE)
  })

  # PR preview is in a preview/pr# subdirectory of gh-pages branch
  dest_preview <- file.path("preview", paste0("pr", Sys.getenv("PR_NUMBER")))
  dest_dir_preview <- fs::dir_create(fs::path(dest_dir, dest_preview))

  url_base <- yaml::read_yaml("pkgdown/_pkgdown.yml")$url

  # Build the preview site in the <gh-pages>/preview/pr#/ directory
  pkgdown:::build_site_github_pages(
    dest_dir = dest_dir_preview,
    override = list(
      url = file.path(url_base, dest_preview)
    ),
    clean = TRUE
  )

  msg <- paste("[preview]", pkgdown:::construct_commit_message("."))
  pkgdown:::github_push(dest_dir, msg, "origin", "gh-pages")
})

