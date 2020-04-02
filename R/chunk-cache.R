
# TODO: how/when to clear cache?
# Store a setup chunk
setup_chunks <- new.env()
storeSetupChunk <- function(name, code){
  assign(name, code, envir=setup_chunks)
}