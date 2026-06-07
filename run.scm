(use-modules (ice-9 rdelim)
             (ice-9 popen))

(define *audio-file* "bad_apple.mp3")
(define *frames-dir* "frames-ascii")
(define *frame-delay* 0.033)  ; ~30 FPS (1000 мс / 30 ≈ 33.3 мс)
(define *clear-cmd* "printf \"\\033c\"")

(define (sleep secs)
  (let ((millisecs (inexact->exact (round (* secs 1000)))))
    (usleep (* millisecs 1000))))

(define (get-frame-files dir)
  (let* ((ls-pipe (open-input-pipe (string-append "ls " dir " | sort -V")))
         (files '()))
    (do ((line (read-line ls-pipe) (read-line ls-pipe)))
        ((eof-object? line))
      (set! files (cons line files)))
    (close-pipe ls-pipe)
    (reverse files)))

(define (read-frame-file dir filename)
  (let* ((full-path (string-append dir "/" filename))
         (port (open-input-file full-path))
         (content (read-delimited "" port)))
    (close-port port)
    content))

(define (play-animation)
  (if (not (file-exists? *frames-dir*))
      (error (string-append ">> Directory not found: " *frames-dir*)))
  (if (not (file-exists? *audio-file*))
      (error (string-append ">> Audio file not found: " *audio-file*)))

  (display ">> Loading frames...\n")
  (let* ((frame-names (get-frame-files *frames-dir*))
         (total-frames (length frame-names)))
    (format #t ">> ~a frames found.\n" total-frames)

    (let* ((audio-cmd (string-append "ffplay -nodisp -autoexit " *audio-file*
                                     " > /dev/null 2>&1 &"))
           (pid (system audio-cmd)))
      (format #t ">> Starting audio player (PID: ~a)...\n" pid))

    (sleep 0.2)

    (let loop ((frames frame-names)
               (frame-num 1))
      (if (null? frames)
          (begin
            (display ">> Animation finished.\n"))
          (begin
            (system *clear-cmd*)
            (let ((frame-data (read-frame-file *frames-dir* (car frames))))
              (display frame-data))
            (sleep *frame-delay*)
            (loop (cdr frames) (+ frame-num 1)))))))

(play-animation)
