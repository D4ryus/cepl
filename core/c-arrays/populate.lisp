(in-package :cepl.c-arrays)

(defun+ c-populate (c-array data &optional (check-sizes t))
  (let ((structp (c-array-struct-element-typep c-array)))
    (labels ((walk-to-dpop (data dimensions idx)
               (let ((dim-size (first dimensions))
                     (dims-rest (rest dimensions)))
                 (if dims-rest
                     (loop
                        :for elem :in data
                        :for i :below dim-size
                        :do (setf idx (walk-to-dpop elem dims-rest idx)))
                     (loop
                        :for elem :in data
                        :for i :below dim-size
                        :do (progn
                              (if structp
                                  (populate (row-major-aref-c c-array idx) elem)
                                  (setf (row-major-aref-c c-array idx) elem))
                              (incf idx))))
                 idx))
             (dpop-with-array (data)
               (loop
                  :for i :below (array-total-size data)
                  :for elem := (row-major-aref data i)
                  :do (if structp
                          (populate (row-major-aref-c c-array i) elem)
                          (setf (row-major-aref-c c-array i) elem)))))
      (when check-sizes
        (unless (validate-dimensions data (c-array-dimensions c-array))
          (error "Dimensions of array differs from that of the data:~%~a~%~a"
                 c-array data)))
      (typecase data
        (array (dpop-with-array data))
        (sequence (walk-to-dpop data
                                (reverse (c-array-dimensions c-array))
                                0)))
      c-array)))

(defun+ rm-index-to-coords (index subscripts)
  (let ((cur index))
    (nreverse
     (loop :for s :in subscripts :collect
        (multiple-value-bind (x rem) (floor cur s)
          (setq cur x)
          rem)))))

(defun+ validate-dimensions (data dimensions)
  (labels ((validate-arr-dimensions (data dimensions)
             (when (equal (array-dimensions data)
                          dimensions)
               dimensions))
           (validate-seq-dimensions (data dimensions)
             (and (equal (length data) (first dimensions))
                  (if (rest dimensions)
                      (validate-seq-dimensions (first data) (rest dimensions))
                      t))))
    (let* ((dimensions (listify dimensions)))
      (typecase data
                (array (validate-arr-dimensions data (reverse dimensions)))
                (sequence (validate-seq-dimensions data (reverse dimensions)))
                (otherwise nil)))))

;;------------------------------------------------------------

(defun+ c-array-byte-size (c-array)
  (%gl-calc-byte-size (c-array-element-byte-size c-array)
                      (c-array-dimensions c-array)))

(defun+ %gl-calc-byte-size (elem-size dimensions)
  (let* ((row-length (first dimensions))
         (row-byte-size (* row-length elem-size)))
    (values (* (reduce #'* dimensions) elem-size)
            row-byte-size)))

(defun+ gl-calc-byte-size (type dimensions)
  (%gl-calc-byte-size (gl-type-size type) (listify dimensions)))
