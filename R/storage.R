

save_question_submission <- function(session, label, question, answers, correct) {
  save_object(
    session = session, 
    object_id = label, 
    tutor_object("question_submission", list(
      question = question,
      answers = answers,
      correct = correct
    ))
  )
}

save_exercise_submission <- function(session, label, code, output, error_message, checked, feedback) {
  
  # for client storage we only forward error output. this is because we want
  # to replay errors back into the client with no execution (in case they were 
  # timeout errors as a result of misbehaving code). for other outputs the client
  # will just tickle the inputs to force re-execution of the outputs.
  storage <- tutor_storage(session)
  if (identical(storage$type, "client")) {
    if (!is.null(error_message))
      output <- error_message_html(error_message)
    else
      output <- NULL
  }
   
  # save object
  save_object(
    session = session, 
    object_id = label, 
    tutor_object("exercise_submission", list(
      code = code,
      output = output,
      checked = checked,
      feedback = feedback
    ))
  )  
}

save_video_progress <- function(session, video_url, time, total_time) {
  save_object(
    session = session, 
    object_id = video_url, 
    tutor_object("video_progress", list(
      time = time,
      total_time = total_time
    ))
  )
}

client_state_object_id <- "tutor-client-state-825E9CBB-FF7A-4C2C-A201-A075AB758F34"

save_client_state <- function(session, data) {
  save_object(
    session = session,
    object_id = client_state_object_id,
    tutor_object("client_state", data)
  )
}

get_client_state <- function(session) {
  object <- get_object(session, client_state_object_id)
  if (!is.null(object))
    object$data
  else
    list()
}

get_exercise_submission <- function(session, label) {
  get_object(session = session, object_id = label)
}


get_all_state_objects <- function(session, exercise_output = TRUE) {
  
  # get all of the objects
  objects <- get_objects(session)
  
  # strip output (the client doesn't need it and it's expensive to transmit)
  objects <- lapply(objects, function(object) {
    if (object$type == "exercise_submission")
      if (!exercise_output)
        object$data["output"] <- list(NULL)
    object
  })
  
  # return objects
  objects
}

filter_state_objects <- function(state_objects, types) {
  Filter(x = state_objects, function(object) {
    object$type %in% types
  })
}

submissions_from_state_objects <- function(state_objects) {
  filter_state_objects(state_objects, c("question_submission", "exercise_submission"))
}

video_progress_from_state_objects <- function(state_objects) {
  filter_state_objects(state_objects, c("video_progress"))
}

progress_events_from_state_objects <- function(state_objects) {

  # first submissions
  submissions <- submissions_from_state_objects(state_objects)
  progress_events <- lapply(submissions, function(submission) {
    if (submission$type == "question_submission") {
      correct <- submission$data$correct
    }
    else if (submission$type == "exercise_submission") {
      if (!is.null(submission$data$feedback))
        correct <- submission$data$feedback$correct
      else
        correct <- TRUE
    }
    
    list(event = submission$type,
         data = list(
           label = submission$id, 
           correct = correct
         ))
  })
  
  # now video_progress
  video_progress <- video_progress_from_state_objects(state_objects)
  video_progress_events <- lapply(video_progress, function(progress) {
    list(event = "video_progress",
         data = list(
           video_url = progress$id,
           time = progress$data$time,
           total_time = progress$data$total_time
         ))
  })
  
  # return lists appended together
  append(progress_events, video_progress_events)
}

save_object <- function(session, object_id, data) {
  tutorial_id <- read_request(session, "tutor.tutorial_id")
  tutorial_version <- read_request(session, "tutor.tutorial_version")
  user_id <- read_request(session, "tutor.user_id")
  data$id <- object_id
  tutor_storage(session)$save_object(tutorial_id, tutorial_version, user_id, object_id, data)
}

get_object <- function(session, object_id) {
  tutorial_id <- read_request(session, "tutor.tutorial_id")
  tutorial_version <- read_request(session, "tutor.tutorial_version")
  user_id <- read_request(session, "tutor.user_id")
  tutor_storage(session)$get_object(tutorial_id, tutorial_version, user_id, object_id)
}

get_objects <- function(session) {
  tutorial_id <- read_request(session, "tutor.tutorial_id")
  tutorial_version <- read_request(session, "tutor.tutorial_version")
  user_id <- read_request(session, "tutor.user_id")
  tutor_storage(session)$get_objects(tutorial_id, tutorial_version, user_id)
}

remove_all_objects <- function(session) {
  tutorial_id <- read_request(session, "tutor.tutorial_id")
  tutorial_version <- read_request(session, "tutor.tutorial_version")
  user_id <- read_request(session, "tutor.user_id")
  tutor_storage(session)$remove_all_objects(tutorial_id, tutorial_version, user_id)
}

initialize_objects_from_client <- function(session, objects) {
  tutorial_id <- read_request(session, "tutor.tutorial_id")
  tutorial_version <- read_request(session, "tutor.tutorial_version")
  user_id <- read_request(session, "tutor.user_id")
  client_storage(session)$initialize_objects_from_client(tutorial_id,
                                                         tutorial_version,
                                                         user_id,
                                                         objects)
}

# helper to form a tutor object (type + data)
tutor_object <- function(type, data) {
  list(
    type = type,
    data = data
  )
}


# get the currently active storage handler
tutor_storage <- function(session) {
  
  # local storage implementation
  local_storage <- filesystem_storage(
    file.path(rappdirs::user_data_dir(), "R", "tutor", "storage")
  )
  
  # function to determine "auto" storage
  auto_storage <- function() {
    location <- read_request(session, "tutor.http_location")
    if (is_localhost(location))
      local_storage
    else
      client_storage(session)
  }
  
  # examine the option
  storage <- getOption("tutor.storage", default = "auto")

  # resolve NULL to "none"
  if (is.null(storage))
    storage <- "none"
  
  # if it's a character vector then resolve it
  if (is.character(storage)) {
    storage <- switch(storage,
      auto = auto_storage(),
      local = local_storage,
      client = client_storage(session),
      none = no_storage()
    )
  }
  
  # verify that storage is a list
  if (!is.list(storage))
    stop("tutor.storage must be a 'auto', 'local', 'client', 'none' or a ", 
         "list of storage functions")
  
  # validate storage interface
  if (is.null(storage$save_object))
    stop("tutor.storage must implement the save_object function")
  if (is.null(storage$get_object))
    stop("tutor.storage must implement the get_object function")
  if (is.null(storage$get_objects))
    stop("tutor.storage must implements the get_objects function")
  
  # return it
  storage
}


#' Filesystem-based storage for tutor state data
#' 
#' Tutorial state storage handler that uses the filesystem
#' as a backing store. The direcotry will contain tutorial
#' state data partitioned by user_id, tutorial_id, and 
#' tutorial_version (in that order)
#' 
#' @param dir Directory to store state data within
#' @param compress Should \code{.rds} files be compressed?
#' 
#' @return Storage handler suitable for \code{options(tutor.storage = ...)}
#' 
#' @export
filesystem_storage <- function(dir, compress = TRUE) {
  
  # helpers to transform ids into valid filesystem paths
  id_to_filesystem_path <- function(id) {
    id <- gsub("..", "", id, fixed = TRUE)
    utils::URLencode(id, reserved = TRUE, repeated = TRUE)
  }
  id_from_filesystem_path <- function(path) {
    utils::URLdecode(path)
  }
  
  # get the path to storage (ensuring that the directory exists)
  storage_path <- function(tutorial_id, tutorial_version, user_id) {
    path <- file.path(dir, 
                      id_to_filesystem_path(user_id),
                      id_to_filesystem_path(tutorial_id),
                      id_to_filesystem_path(tutorial_version))
    if (!utils::file_test("-d", path))
      dir.create(path, recursive = TRUE)
    path
  }
  
  # functions which implement storage via saving to RDS
  list(
    
    type = "local",
    
    save_object = function(tutorial_id, tutorial_version, user_id, object_id, data) {
      object_path <- file.path(storage_path(tutorial_id, tutorial_version, user_id), 
                               paste0(id_to_filesystem_path(object_id), ".rds"))
      saveRDS(data, file = object_path, compress = compress)
    },
    
    get_object = function(tutorial_id, tutorial_version, user_id, object_id) {
      object_path <- file.path(storage_path(tutorial_id, tutorial_version, user_id), 
                               paste0(id_to_filesystem_path(object_id), ".rds"))
      if (file.exists(object_path))
        readRDS(object_path)
      else
        NULL
    },
    
    get_objects = function(tutorial_id, tutorial_version, user_id) {
      objects_path <- storage_path(tutorial_id, tutorial_version, user_id)
      objects <- list()
      for (object_path in list.files(objects_path, pattern = utils::glob2rx("*.rds"))) {
        object <- readRDS(file.path(objects_path, object_path))
        object_id <- sub("\\.rds$", "", id_from_filesystem_path(object_path))
        objects[[length(objects) + 1]] <- object
      }
      objects
    },
    
    remove_all_objects = function(tutorial_id, tutorial_version, user_id) {
      objects_path <- storage_path(tutorial_id, tutorial_version, user_id)
      unlink(objects_path, recursive = TRUE)
    }
  ) 
}

# client side storage implementation. data is saved by broadcasting it to the client
# this data is subsequently restored during initialize and stored in a per-session
# in memory table for retreival
client_storage <- function(session) {
  
  
  # helper to form a unique tutorial context id (note that we don't utilize the user_id
  # as there is no concept of server-side user in client_storage, user scope is 100% 
  # determined by connecting user agent)
  tutorial_context_id <- function(tutorial_id, tutorial_version) {
    paste(tutorial_id, tutorial_version, sep = "-")
  }
  
  # get a reference to the session object cache for a gvien tutorial context
  object_store <- function(context_id) {
    
    # create session objects on demand
    session_objects <- read_request(session, "tutor.session_objects")
    if (is.null(session_objects)) {
      session_objects <- new.env(parent = emptyenv())
      write_request(session, "tutor.session_objects", session_objects)
    }
    
    # create entry for this context on demand
    if (!exists(context_id, envir = session_objects))
      assign(context_id, new.env(parent = emptyenv()), envir = session_objects)
    store <- get(context_id, envir = session_objects)
    
    # return reference to the store
    store
  }
  
  list(
    
    type = "client",
  
    save_object = function(tutorial_id, tutorial_version, user_id, object_id, data) {
      
      # save the object to our in-memory store
      context_id <- tutorial_context_id(tutorial_id, tutorial_version)
      store <- object_store(context_id)
      assign(object_id, data, envir = store)
     
      # broadcast to client
      session$sendCustomMessage("tutor.store_object", list(
        context = context_id,
        id = object_id,
        data = jsonlite::serializeJSON(data)
      ))
    },
    
    get_object = function(tutorial_id, tutorial_version, user_id, object_id) {
      context_id <- tutorial_context_id(tutorial_id, tutorial_version)
      store <- object_store(context_id)
      if (exists(object_id, envir = store))
        get(object_id, envir = store)
      else
        NULL
    },
    
    get_objects = function(tutorial_id, tutorial_version, user_id) { 
      context_id <- tutorial_context_id(tutorial_id, tutorial_version)
      store <- object_store(context_id)
      objects <- list()
      for (object in ls(store))
        objects[[length(objects) + 1]] <- get(object, envir = store)
      objects
    },
    
    remove_all_objects = function(tutorial_id, tutorial_version, user_id) {
      # remove on server side (client side is handled on client)
      context_id <- tutorial_context_id(tutorial_id, tutorial_version)
      store <- object_store(context_id)
      rm(list = ls(store), envir = store)
    },
    
    # function called from initialize to prime object storage from the browser db
    initialize_objects_from_client = function(tutorial_id, tutorial_version, user_id, objects) {
      context_id <- tutorial_context_id(tutorial_id, tutorial_version)
      store <- object_store(context_id)
      for (object_id in names(objects)) {
        data <- jsonlite::unserializeJSON(objects[[object_id]])
        assign(object_id, data, envir = store)
      }
    }
  )
}


# no-op storage implementation
no_storage <- function() {
  list(
    type = "none",
    save_object = function(tutorial_id, tutorial_version, user_id, object_id, data) {},
    get_object = function(tutorial_id, tutorial_version, user_id, object_id) { NULL },
    get_objects = function(tutorial_id, tutorial_version, user_id) { list() },
    remove_all_objects = function(tutorial_id, tutorial_version, user_id) {}
  )
}



