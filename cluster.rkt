(begin
  (define sys (dynamic-require "sys" none))
  (define os-mod (dynamic-require "os" none))
  (define cwd (vm-apply (=> os-mod "getcwd") '()))
  (define _ (vm-apply (=> (=> sys "path") "insert") (cons 0 (cons cwd null))))
  (define helper (dynamic-require "cluster_helper" none))

  ((lambda ()
     (define cfg (vm-apply (=> helper "get_config_from_env") '()))
     (define video (@ cfg 0))
     (define k (@ cfg 1))
     (define out (@ cfg 2))
     (define max-n (@ cfg 3))
     (define sz (@ cfg 4))

     (let/cc exit
       (if (or (eq? video none) (equal? video ""))
           (exit (begin
                   (vm-apply (=> (=> sys "stderr") "write")
                             (cons "Error: video path is required\n" null))
                   none))
           none)
       (if (not (vm-apply (=> (=> os-mod "path") "exists") (cons video null)))
           (exit (begin
                   (vm-apply (=> (=> sys "stderr") "write")
                             (cons "Error: video file not found: " null))
                   (vm-apply (=> (=> sys "stderr") "write") (cons video null))
                   (vm-apply (=> (=> sys "stderr") "write") (cons "\n" null))
                   none))
           none)

       ;; Clustering in nested lambda — only reached if checks pass
       ((lambda ()
          (print "Video: ")
          (print video)
          (print "  Clusters: ")
          (print k)
          (print "  Max frames: ")
          (print max-n)

          (define data (vm-apply (=> helper "extract_and_init")
                                  (cons video (cons max-n (cons sz null)))))
          (define clusters (@ data 0))
          (define cntroids (@ data 1))
          (define sizes (@ data 2))
          (define active (@ data 3))
          (define n (@ data 4))
          (define ac n)

          (let cluster-loop ()
            (if (<= ac k)
                none
                (begin
                  (define min-dist 1e100)
                  (define min-i -1)
                  (define min-j -1)

                  (let i-loop ((i 0))
                    (if (equal? i n)
                        none
                        (begin
                          (if (@ active i)
                              (let j-loop ((j (+ i 1)))
                                (if (equal? j n)
                                    none
                                    (begin
                                      (if (@ active j)
                                          (let ((d (vm-apply (=> helper "vec_distance_sq")
                                                             (cons (@ cntroids i)
                                                                   (cons (@ cntroids j) null)))))
                                            (if (< d min-dist)
                                                (begin
                                                  (set! min-dist d)
                                                  (set! min-i i)
                                                  (set! min-j j))
                                                none))
                                          none)
                                      (j-loop (+ j 1)))))
                              none)
                          (i-loop (+ i 1)))))

                  (let merge-loop ((m 0))
                    (if (equal? m (@ sizes min-j))
                        none
                        (begin
                          (<! (@ clusters min-i) (@ (@ clusters min-j) m))
                          (merge-loop (+ m 1)))))

                  (define nc (vm-apply (=> helper "avg_centroids")
                                        (cons (@ cntroids min-i)
                                              (cons (@ sizes min-i)
                                                    (cons (@ cntroids min-j)
                                                          (cons (@ sizes min-j) null))))))
                  (! cntroids min-i nc)
                  (! sizes min-i (+ (@ sizes min-i) (@ sizes min-j)))
                  (! active min-j #f)
                  (set! ac (- ac 1))

                  (cluster-loop))))

          (vm-apply (=> helper "find_and_save_medoids")
                    (cons active
                          (cons cntroids
                                (cons clusters
                                      (cons n
                                            (cons out null))))))
          (print "Done.")))))))
