
class __learnr__:
  '''An internal class to provide Python utility functions'''
  
  @staticmethod
  def deep_copy(dict, deep=True):
    import copy
    from types import ModuleType
    new_dict = {}
    for k, v in dict.items():
      if (k == "r" or isinstance(v, ModuleType)):
        new_dict[k] = v
      else:
        new_dict[k] = copy.deepcopy(v) if deep else v
    return new_dict
