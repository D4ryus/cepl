(in-package :%cepl.types)

;;------------------------------------------------------------

(defstruct (c-array (:constructor %make-c-array))
  (pointer
   (error "cepl: c-array must be created with a pointer")
   :type cffi-sys:foreign-pointer)
  (dimensions
   (error "cepl: c-array must be created with dimensions")
   :type list)
  (element-type
   (error "cepl: c-array must be created with an element-type")
   :type symbol)
  (element-byte-size
   (error "cepl: c-array must be created with an element-byte-size")
   :type fixnum)
  (struct-element-typep nil :type boolean)
  (row-byte-size
   (error "cepl: c-array must be created with a pointer")
   :type fixnum)
  (element-pixel-format nil :type (or null cepl.pixel-formats:pixel-format)))

;;------------------------------------------------------------

(defclass gl-texture ()
  ((texture-id :initarg :texture-id :reader texture-id)
   (base-dimensions :initarg :base-dimensions :accessor base-dimensions)
   (texture-type :initarg :texture-type :reader texture-type)
   (internal-format :initarg :internal-format :reader internal-format)
   (sampler-type :initarg :sampler-type :reader sampler-type)
   (mipmap-levels :initarg :mipmap-levels)
   (layer-count :initarg :layer-count)
   (cubes :initarg :cubes)
   (allocated :initform nil :reader allocatedp)
   (sampler-object-id :initform 0)))

;;------------------------------------------------------------

(defstruct (gpu-buffer (:constructor %make-gpu-buffer))
  "This is our opengl buffer object. Along with the opengl
   buffer name (buffer-id) we also store the layout of the data
   within the buffer.
   This layout is as follows:
   `((data-type data-index-length offset-in-bytes-into-buffer))
   for example:
   `((:float 3 0) ('vert-data 140 12))"
  (id 0 :type fixnum)
  (format nil :type list)
  (managed nil :type boolean))

(defvar +null-gpu-buffer+ (%make-gpu-buffer))

;;------------------------------------------------------------

(defstruct (gpu-array (:constructor %make-gpu-array))
  (dimensions nil :type list))

(defstruct (gpu-array-bb (:constructor %make-gpu-array-bb)
			 (:include gpu-array))
  (buffer (error "") :type gpu-buffer)
  (format-index 0 :type fixnum)
  (start 0 :type fixnum)
  (access-style :static-draw :type symbol))

(defstruct (gpu-array-t (:constructor %make-gpu-array-t)
			(:include gpu-array))
  (texture (error "") :type gl-texture)
  (texture-type (error "") :type symbol)
  (level-num 0 :type fixnum)
  (layer-num 0 :type fixnum)
  (face-num 0 :type fixnum)
  (internal-format nil :type symbol))

;;------------------------------------------------------------

(defclass immutable-texture (gl-texture) ())
(defclass mutable-texture (gl-texture) ())
(defclass buffer-texture (gl-texture)
  ((backing-array :initarg :backing-array)
   (owns-array :initarg :owns-array)))

;;------------------------------------------------------------

;; {TODO} border-color
(defstruct (sampler (:constructor %make-sampler)
                    (:conc-name %sampler-))
  (id -1 :type fixnum)
  (lod-bias 0.0 :type single-float)
  (min-lod -1000.0 :type single-float)
  (max-lod 1000.0 :type single-float)
  (expects-mipmap nil :type boolean)
  (minify-filter :linear :type keyword)
  (magnify-filter :linear :type keyword)
  (wrap #(:repeat :repeat :repeat) :type vector)
  (expects-depth nil :type boolean)
  (compare nil :type symbol))

;;------------------------------------------------------------

(defstruct (ubo (:constructor %make-ubo))
  (id 0 :type fixnum)
  (data (error "gpu-array must be provided when making ubo")
	:type gpu-array)
  (index 0 :type fixnum)
  (owns-gpu-array nil :type boolean))

;;------------------------------------------------------------

(defstruct blending-params
  (mode-rgb :func-add :type keyword)
  (mode-alpha :func-add :type keyword)
  (source-rgb :src-alpha :type keyword)
  (source-alpha :src-alpha :type keyword)
  (destination-rgb :one-minus-src-alpha :type keyword)
  (destination-alpha :one-minus-src-alpha :type keyword))

;;------------------------------------------------------------

(defstruct (fbo (:constructor %%make-fbo)
                (:conc-name %fbo-))
  (id -1 :type fixnum)
  (attachment-color (error "")
                    :type (array attachment *))
  (draw-buffer-map (error ""))
  (attachment-depth (%make-attachment) :type attachment)
  (clear-mask (cffi:foreign-bitfield-value
               '%gl::ClearBufferMask '(:color-buffer-bit))
              :type fixnum)
  (is-default nil :type boolean)
  (blending-params (make-blending-params :mode-rgb :func-add
					 :mode-alpha :func-add
					 :source-rgb :one
					 :source-alpha :one
					 :destination-rgb :zero
					 :destination-alpha :zero)
		   :type blending-params))


(defstruct (attachment (:constructor %make-attachment)
                       (:conc-name %attachment-))
  (fbo nil :type (or null fbo))
  (gpu-array nil :type (or null gpu-array-t))
  (owns-gpu-array nil :type boolean)
  (blending-enabled nil :type boolean)
  (override-blending nil :type boolean)
  (blending-params (cepl.blending:make-blending-params
		    :mode-rgb :func-add
		    :mode-alpha :func-add
		    :source-rgb :one
		    :source-alpha :one
		    :destination-rgb :zero
		    :destination-alpha :zero) :type blending-params))

;;------------------------------------------------------------

(defstruct pixel-format
  (components (error "") :type symbol)
  (type (error "") :type symbol)
  (normalise t :type boolean)
  (sizes nil :type list)
  (reversed nil :type boolean)
  (comp-length 0 :type fixnum))

;;------------------------------------------------------------

(defstruct (buffer-stream (:constructor make-raw-buffer-stream
                                        (&key vao start length
                                              index-type managed
                                              gpu-arrays)))
  "buffer-streams are the structure we use in cepl to pass
   information to our programs on what to draw and how to draw
   it.

   It basically adds the only things that arent captured in the
   vao but are needed to draw, namely the range of data to draw
   and the style of drawing.

   If you are using c-arrays then be sure to use the
   make-buffer-stream function as it does all the
   work for you."
  vao
  (start 0 :type unsigned-byte)
  (length 1 :type unsigned-byte)
  (index-type nil :type symbol)
  (gpu-arrays nil :type list)
  (managed nil :type boolean))

;;------------------------------------------------------------

;;{NOTE} if optimization called for it this could easily be an
;;       array of 16bit ints (or whatever works)
(defstruct (viewport (:conc-name %viewport-) (:constructor %make-viewport))
  (resolution-x 320 :type fixnum)
  (resolution-y 240 :type fixnum)
  (origin-x 0 :type fixnum)
  (origin-y 0 :type fixnum))
