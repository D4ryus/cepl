(in-package :cepl-utils)

;;----------------------------------------------------------------------

(defconstant +gl-enum-size+
  #.(* 8 (cffi:foreign-type-size '%gl::enum)))

;;----------------------------------------------------------------------
