(in-package #:coding-math.2d.demo)

;;;; Config
(setf *bypass-cache* t)
(defparameter *width* 600)
(defparameter *height* 400)

(defparameter *center-x* (/ *width* 2))
(defparameter *center-y* (/ *height* 2))

(defvar *shift* nil)
(defvar *control* nil)
(defvar *command* nil)
(defvar *option* nil)


;;;; Utils
(defmacro with-setup (&body body)
  `(with-fps
    (background (gray 1))
    ,@body))

(defun oob-p (p &optional (r 0.0))
  (or (outsidep (- 0 r) (+ *width* r) (vec-x p))
      (outsidep (- 0 r) (+ *height* r) (vec-y p))))

(defun real-time ()
  (/ (get-internal-real-time) internal-time-units-per-second))

(defun random-location ()
  (make-random-vec *width* *height*))

(defun random-location-centered ()
  (make-vec (random-range (- *center-x*) *center-x*)
            (random-range (- *center-y*) *center-y*)))


;;;; Sketch
(defun draw-particle (p)
  (circle (particle-x p) (particle-y p) (particle-radius p)))

(defun draw-line (p1 p2)
  (with-vecs ((x1 y1) p1 (x2 y2) p2)
    (line x1 y1 x2 y2)))

(defun draw-circle (p &optional (radius 5))
  (if (listp p)
    (circle (getf p :x) (getf p :y) (or (getf p :radius) radius))
    (circle (vec-x p) (vec-y p) radius)))

(defun draw-square (p radius)
  (rect (- (vec-x p) radius)
        (- (vec-y p) radius)
        (* 2 radius)
        (* 2 radius)))

(defun draw-polygon (points)
  (when points
    ;; why is this fucked?
    (apply #'polygon
           (iterate (for p :in points)
                    (collect (vec-x p))
                    (collect (vec-y p))))))

(defun draw-triangle (p1 p2 p3)
  #+sketch-polygon-fn-is-fucked (polygon (vec-x p1) (vec-y p1)
                                         (vec-x p2) (vec-y p2)
                                         (vec-x p3) (vec-y p3))
  (let ((vertices (list (vec-to-list p1)
                        (vec-to-list p2)
                        (vec-to-list p3))))
    (sketch::draw-shape :triangles vertices vertices)))


(defun draw-tree (p0 p1 branch-angle-a branch-angle-b trunk-ratio limit)
  (if (zerop limit)
    (draw-line p0 p1)
    (let* ((d (vec-mul (vec-sub p1 p0) trunk-ratio))
           (midpoint (vec-add d p0)))
      (draw-line p0 midpoint)
      (draw-tree midpoint (vec-add midpoint (vec-rotate d branch-angle-a))
                 branch-angle-a branch-angle-b trunk-ratio (1- limit))
      (draw-tree midpoint (vec-add midpoint (vec-rotate d branch-angle-b))
                 branch-angle-a branch-angle-b trunk-ratio (1- limit)))))

(defun draw-pytree (size angle limit)
  (rect 0 0 size size)
  (when (not (zerop limit))
    (let ((a-size (* size (cos angle)))
          (b-size (* size (sin angle))))
      (in-context
        (translate 0 size)
        (rotate (degrees angle))
        (draw-pytree a-size angle (1- limit)))
      (in-context
        (translate size size)
        (rotate (- (- 180 90 (degrees angle))))
        (translate (- b-size) 0)
        (draw-pytree b-size angle (1- limit))
        )
      )

    )
  )

(defsketch demo
    ((width *width*) (height *height*) (y-axis :up) (title "Coding Math 2D")
     (copy-pixels nil)
     (mouse (make-vec 0 0))
     (frame 0)
     (start-time (real-time))
     (current-time 0)
     (previous-time 0)
     (total-time 0)
     ;; Data
     (p0 (make-vec *center-x* 50))
     (p1 (make-vec *center-x* (- *height* 200)))
     (branch-angle-a (random-range (- (/ tau 4)) (/ tau 4)))
     (branch-angle-b (random-range (- (/ tau 4)) (/ tau 4)))
     (trunk-ratio 1/2)

     (py-angle (/ tau 8))

     (a 0.0)
     ;; Pens
     (particle-pen (make-pen :fill (gray 0.9) :stroke (gray 0.4)))
     (black-pen (make-pen :stroke (rgb 0 0 0) :fill (rgb 0.4 0.4 0.4) :weight 1 :curve-steps 50))
     (red-pen (make-pen :stroke (rgb 0.6 0 0) :fill (rgb 0.9 0 0) :weight 1 :curve-steps 50))
     (green-pen (make-pen :stroke (rgb 0 0.6 0) :fill (rgb 0 0.9 0) :weight 1 :curve-steps 50))
     (blue-pen (make-pen :stroke (rgb 0 0 0.6) :fill (rgb 0 0 0.9) :weight 1 :curve-steps 50))
     )
  (setf previous-time current-time
        current-time (real-time))
  (incf total-time (- current-time previous-time))
  (incf frame)
  ;;
  (incf a 0.02)
  (wrapf a 0 tau)

  (setf trunk-ratio (map-range -1 1 1/4 3/4 (sin a)))

  (setf py-angle (map-range 0 tau 0 (/ tau 4) a))

  (with-setup
    (in-context
      (with-pen black-pen
        (in-context
          (translate (- *center-x* 40) 0)
          (draw-pytree 80 py-angle 5)))
      (with-pen red-pen
        (draw-tree p0 p1 branch-angle-a branch-angle-b trunk-ratio 8))
      ))
  ;;

  )


;;;; Mouse
(defun mousemove (instance x y)
  (with-slots (mouse) instance
    (setf mouse (make-vec x (- *height* y)))
    ;;
    ;;
    )
  )


(defun mousedown-left (instance x y)
  (declare (ignorable instance x y))
  )

(defun mousedown-right (instance x y)
  (declare (ignorable instance x y))
  )

(defun mouseup-left (instance x y)
  (declare (ignorable instance x y))
  )

(defun mouseup-right (instance x y)
  (declare (ignorable instance x y))
  )


(defmethod kit.sdl2:mousemotion-event ((window demo) ts b x y xrel yrel)
  (declare (ignore ts b xrel yrel))
  (mousemove window x y))

(defmethod kit.sdl2:mousebutton-event ((window demo) state ts button x y)
  (declare (ignore ts))
  (funcall (case state
             (:mousebuttondown
              (case button
                (1 #'mousedown-left)
                (3 #'mousedown-right)))
             (:mousebuttonup
              (case button
                (1 #'mouseup-left)
                (3 #'mouseup-right))))
           window x y))


;;;; Keyboard
(defun keydown (instance scancode)
  (declare (ignorable instance))
  (scancode-case scancode
    (:scancode-space (sketch::prepare instance))
    (:scancode-lshift (setf *shift* t))
    (:scancode-lctrl (setf *control* t))
    (:scancode-lgui (setf *command* t))
    (:scancode-lalt (setf *option* t))
    ;;
    ;;
    ))

(defun keyup (instance scancode)
  (declare (ignorable instance))
  (scancode-case scancode
    (:scancode-lshift (setf *shift* nil))
    (:scancode-lctrl (setf *control* nil))
    (:scancode-lgui (setf *command* nil))
    (:scancode-lalt (setf *option* nil))
    (:scancode-space nil)))


(defmethod kit.sdl2:keyboard-event ((instance demo) state timestamp repeatp keysym)
  (declare (ignore timestamp repeatp))
  (cond
    ((eql state :keyup) (keyup instance (sdl2:scancode-value keysym)))
    ((eql state :keydown) (keydown instance (sdl2:scancode-value keysym)))
    (t nil)))


;;;; Run
; (defparameter *demo* (make-instance 'demo))
