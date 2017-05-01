options(tutorial.storage = list(

  # save an arbitrary R object "data" to storage
  save_object = function(tutorial_id, tutorial_version, user_id, object_id, data) {
  
  },
  
  # retreive a single R object from storage
  get_object = function(tutorial_id, tutorial_version, user_id, object_id) { 
    NULL 
  },
  
  # retreive a list of all R objects stored
  get_objects = function(tutorial_id, tutorial_version, user_id) { 
    list() 
  },
  
  # remove all stored R objects
  remove_all_objects = function(tutorial_id, tutorial_version, user_id) {
  
  }
)

