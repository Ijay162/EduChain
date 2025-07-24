;; EduChain: Decentralized Educational Achievement Platform
;; Version: 1.0.0

(define-data-var academic-dean principal tx-sender)
(define-data-var knowledge-bank uint u0)
(define-data-var achievement-point-rate uint u110) ;; achievement points per learning cycle
(define-data-var last-point-calculation uint u0) ;; last block when points were calculated

(define-map student-achievements principal uint)

;; Helper function to ensure only the academic dean can perform certain actions
(define-private (is-dean (caller principal))
  (begin
    (asserts! (is-eq caller (var-get academic-dean)) (err u300))
    (ok true)))

;; Initialize the educational achievement platform
(define-public (establish-academy (dean principal))
  (begin
    (asserts! (is-none (map-get? student-achievements dean)) (err u301))
    (var-set academic-dean dean)
    (ok "EduChain academy established")))

;; Record learning achievements
(define-public (record-achievement (skill-points uint))
  (begin
    (asserts! (> skill-points u0) (err u302))
    (let ((current-achievements (default-to u0 (map-get? student-achievements tx-sender))))
      (map-set student-achievements tx-sender (+ current-achievements skill-points))
      (var-set knowledge-bank (+ (var-get knowledge-bank) skill-points))
      (ok (+ current-achievements skill-points)))))

;; Calculate achievement points for all students
(define-public (calculate-achievement-points)
  (begin
    (try! (is-dean tx-sender))
    (let ((current-block stacks-block-height)
          (previous-calculation (var-get last-point-calculation)))
      (asserts! (> current-block previous-calculation) (err u303))
      ;; Calculate points based on blocks elapsed
      (let ((elapsed (- current-block previous-calculation))
            (total-points (* elapsed (var-get achievement-point-rate))))
        (var-set last-point-calculation current-block)
        (var-set knowledge-bank (+ (var-get knowledge-bank) total-points))
        (ok total-points)))))

;; Graduate and claim achievement rewards
(define-public (graduate-with-honors)
  (begin
    (let ((student-progress (default-to u0 (map-get? student-achievements tx-sender))))
      (asserts! (> student-progress u0) (err u304))
      (let ((total-knowledge (var-get knowledge-bank))
            (new-points (* (var-get achievement-point-rate) (- stacks-block-height (var-get last-point-calculation))))
            (achievement-ratio (/ (* student-progress u100000) total-knowledge)))
        ;; Calculate honors based on achievement ratio
        (let ((honors-amount (/ (* achievement-ratio new-points) u100000)))
          (map-delete student-achievements tx-sender)
          (var-set knowledge-bank (- (var-get knowledge-bank) student-progress))
          (ok (+ student-progress honors-amount)))))))

;; Read-only functions
(define-read-only (get-student-achievements (student principal))
  (default-to u0 (map-get? student-achievements student)))

(define-read-only (get-academy-stats)
  {
    dean: (var-get academic-dean),
    total-knowledge: (var-get knowledge-bank),
    point-rate: (var-get achievement-point-rate),
    last-calculation: (var-get last-point-calculation)
  })

(define-read-only (get-knowledge-bank)
  (var-get knowledge-bank))