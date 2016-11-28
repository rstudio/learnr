

save_question_submission <- function(session, label, question, answers) {
  save_object(session, label, tutor_object("question_submission", list(
    question = question,
    answers = answers
  )))
}

save_exercise_submission <- function(session, label, code, output, feedback) {
  save_object(session, label, tutor_object("exercise_submission", list(
    code = code,
    output = output,
    feedback = feedback
  )))  
}

save_object <- function(session, object_id, data) {
  tutorial_id <- read_request(session, "tutor.tutorial_id")
  user_id <- read_request(session, "tutor.user_id")
  storage()$save_object(tutorial_id, user_id, object_id, data)
}

get_object <- function(session, object_id) {
  tutorial_id <- read_request(session, "tutor.tutorial_id")
  user_id <- read_request(session, "tutor.user_id")
  storage()$get_object(tutorial_id, user_id, object_id)
}

get_objects <- function(session) {
  tutorial_id <- read_request(session, "tutor.tutorial_id")
  user_id <- read_request(session, "tutor.user_id")
  storage()$get_objects(tutorial_id, user_id)
}


# helper to form a tutor object (type + data)
tutor_object <- function(type, data) {
  list(
    type = type,
    data = data
  )
}


# get the currently active storage handler
storage <- function() {
  getOption("tutor.storage", 
            default = filesystem_storage(
              file.path(rappdirs::user_data_dir(), "R", "tutor", "storage"))
            )
}


# return an implementation of filesystem storage for specified directory
filesystem_storage <- function(dir, compress = TRUE) {
  
  # helpers to transform ids into valid filesystem paths
  id_to_filesystem_path <- function(id) {
    utils::URLencode(id, reserved = TRUE, repeated = TRUE)
  }
  id_from_filesystem_path <- function(path) {
    utils::URLdecode(path)
  }
  
  # get the path to storage (ensuring that the directory exists)
  storage_path <- function(tutorial_id, user_id) {
    path <- file.path(dir, 
                      id_to_filesystem_path(user_id),
                      id_to_filesystem_path(tutorial_id))
    if (!utils::file_test("-d", path))
      dir.create(path, recursive = TRUE)
    path
  }
  
  # functions which implement storage via saving to RDS
  list(
    
    save_object = function(tutorial_id, user_id, object_id, data) {
      object_path <- file.path(storage_path(tutorial_id, user_id), 
                               paste0(id_to_filesystem_path(object_id), ".rds"))
      saveRDS(data, file = object_path, compress = compress)
    },
    
    get_object = function(tutorial_id, user_id, object_id) {
      object_path <- file.path(storage_path(tutorial_id, user_id), 
                               paste0(id_to_filesystem_path(object_id), ".rds"))
      readRDS(object_path)
    },
    
    get_objects = function(tutorial_id, user_id) {
      objects_path <- storage_path(tutorial_id, user_id)
      objects <- list()
      for (object_path in list.files(objects_path, pattern = utils::glob2rx("*.rds"))) {
        object <- readRDS(file.path(objects_path, object_path))
        object_id <- sub("\\.rds$", "", id_from_filesystem_path(object_path))
        objects[[object_id]] <- object
      }
      objects
    }
  ) 
}





