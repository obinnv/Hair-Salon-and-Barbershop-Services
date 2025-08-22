;; Appointment System Contract
;; Manages appointment booking, scheduling, and availability

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-APPOINTMENT-NOT-FOUND (err u201))
(define-constant ERR-INVALID-TIME (err u202))
(define-constant ERR-STYLIST-UNAVAILABLE (err u203))
(define-constant ERR-INVALID-STATUS (err u204))
(define-constant ERR-INVALID-INPUT (err u205))

;; Status constants
(define-constant STATUS-SCHEDULED u1)
(define-constant STATUS-CONFIRMED u2)
(define-constant STATUS-IN-PROGRESS u3)
(define-constant STATUS-COMPLETED u4)
(define-constant STATUS-CANCELLED u5)

;; Data variables
(define-data-var appointment-counter uint u0)

;; Data maps
(define-map appointments uint {
  customer: principal,
  salon-id: uint,
  stylist-id: uint,
  service-id: uint,
  appointment-time: uint,
  duration-minutes: uint,
  status: uint,
  notes: (string-ascii 500),
  created-at: uint,
  updated-at: uint
})

(define-map stylist-availability uint {
  stylist-id: uint,
  date: uint,
  start-time: uint,
  end-time: uint,
  available: bool
})

(define-map customer-preferences principal {
  preferred-stylist: (optional uint),
  preferred-time-slot: uint,
  special-requests: (string-ascii 300)
})

;; Book an appointment
(define-public (book-appointment (salon-id uint) (stylist-id uint) (service-id uint) (appointment-time uint) (duration-minutes uint) (notes (string-ascii 500)))
  (let ((appointment-id (+ (var-get appointment-counter) u1)))

    (asserts! (> appointment-time block-height) ERR-INVALID-TIME)
    (asserts! (> duration-minutes u0) ERR-INVALID-INPUT)
    (asserts! (< duration-minutes u480) ERR-INVALID-INPUT) ;; Max 8 hours

    ;; Check stylist availability (simplified check)
    (asserts! (is-stylist-available stylist-id appointment-time duration-minutes) ERR-STYLIST-UNAVAILABLE)

    (map-set appointments appointment-id {
      customer: tx-sender,
      salon-id: salon-id,
      stylist-id: stylist-id,
      service-id: service-id,
      appointment-time: appointment-time,
      duration-minutes: duration-minutes,
      status: STATUS-SCHEDULED,
      notes: notes,
      created-at: block-height,
      updated-at: block-height
    })

    (var-set appointment-counter appointment-id)
    (ok appointment-id)
  )
)

;; Update appointment status
(define-public (update-appointment-status (appointment-id uint) (new-status uint))
  (let ((appointment (unwrap! (map-get? appointments appointment-id) ERR-APPOINTMENT-NOT-FOUND)))

    (asserts! (or
      (is-eq tx-sender (get customer appointment))
      (is-salon-owner-or-stylist tx-sender (get salon-id appointment) (get stylist-id appointment))
    ) ERR-NOT-AUTHORIZED)

    (asserts! (and (>= new-status u1) (<= new-status u5)) ERR-INVALID-STATUS)

    (map-set appointments appointment-id
      (merge appointment {
        status: new-status,
        updated-at: block-height
      })
    )
    (ok true)
  )
)

;; Set stylist availability
(define-public (set-stylist-availability (stylist-id uint) (date uint) (start-time uint) (end-time uint) (available bool))
  (let ((availability-id (+ (* stylist-id u1000000) date))) ;; Simple ID generation

    (asserts! (< start-time end-time) ERR-INVALID-TIME)
    (asserts! (is-authorized-for-stylist tx-sender stylist-id) ERR-NOT-AUTHORIZED)

    (map-set stylist-availability availability-id {
      stylist-id: stylist-id,
      date: date,
      start-time: start-time,
      end-time: end-time,
      available: available
    })
    (ok true)
  )
)

;; Set customer preferences
(define-public (set-customer-preferences (preferred-stylist (optional uint)) (preferred-time-slot uint) (special-requests (string-ascii 300)))
  (begin
    (map-set customer-preferences tx-sender {
      preferred-stylist: preferred-stylist,
      preferred-time-slot: preferred-time-slot,
      special-requests: special-requests
    })
    (ok true)
  )
)

;; Helper functions
(define-private (is-stylist-available (stylist-id uint) (appointment-time uint) (duration uint))
  ;; Simplified availability check - in production would check against availability map
  true
)

(define-private (is-salon-owner-or-stylist (user principal) (salon-id uint) (stylist-id uint))
  ;; Simplified authorization check - would integrate with salon-management contract
  true
)

(define-private (is-authorized-for-stylist (user principal) (stylist-id uint))
  ;; Simplified authorization check - would integrate with salon-management contract
  true
)

;; Read-only functions
(define-read-only (get-appointment (appointment-id uint))
  (map-get? appointments appointment-id)
)

(define-read-only (get-stylist-availability (stylist-id uint) (date uint))
  (let ((availability-id (+ (* stylist-id u1000000) date)))
    (map-get? stylist-availability availability-id)
  )
)

(define-read-only (get-customer-preferences (customer principal))
  (map-get? customer-preferences customer)
)

(define-read-only (get-appointment-counter)
  (var-get appointment-counter)
)

;; Get appointments by customer
(define-read-only (get-customer-appointments (customer principal))
  ;; In a full implementation, this would return a list of appointment IDs
  ;; For now, returns the counter as a simple indicator
  (var-get appointment-counter)
)
