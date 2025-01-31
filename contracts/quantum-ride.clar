;; QuantumRide Main Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-invalid-state (err u101))
(define-constant err-insufficient-payment (err u102))

;; Data vars
(define-data-var min-ride-cost uint u1000000) ;; in micro-STX
(define-data-var platform-fee-percent uint u10)
(define-data-var next-ride-id uint u0) ;; Added missing next-ride-id counter

;; Data maps
(define-map rides 
  { ride-id: uint } 
  {
    rider: principal,
    driver: (optional principal),
    pickup: (string-ascii 100),
    dropoff: (string-ascii 100),
    cost: uint,
    status: (string-ascii 20)
  }
)

(define-map drivers
  { driver: principal }
  {
    active: bool,
    rating: uint,
    total-rides: uint
  }
)

;; Public functions
(define-public (request-ride (pickup (string-ascii 100)) (dropoff (string-ascii 100)) (cost uint))
  (let ((ride-id (+ (var-get next-ride-id) u1)))
    (try! (stx-transfer? cost tx-sender (as-contract tx-sender)))
    (map-set rides 
      { ride-id: ride-id }
      {
        rider: tx-sender,
        driver: none,
        pickup: pickup,
        dropoff: dropoff, 
        cost: cost,
        status: "requested"
      }
    )
    (var-set next-ride-id ride-id)
    (ok ride-id)
  )
)

(define-public (accept-ride (ride-id uint))
  (let ((ride (unwrap! (map-get? rides {ride-id: ride-id}) err-invalid-state))
        (driver-info (unwrap! (map-get? drivers {driver: tx-sender}) err-not-authorized)))
    (asserts! (is-eq (get status ride) "requested") err-invalid-state)
    (asserts! (get active driver-info) err-not-authorized)
    (map-set rides
      { ride-id: ride-id }
      (merge ride { 
        driver: (some tx-sender),
        status: "accepted"
      })
    )
    (ok true)
  )
)

(define-public (complete-ride (ride-id uint))
  (let ((ride (unwrap! (map-get? rides {ride-id: ride-id}) err-invalid-state)))
    (asserts! (is-eq (some tx-sender) (get driver ride)) err-not-authorized)
    (asserts! (is-eq (get status ride) "accepted") err-invalid-state)
    
    (let ((fee (/ (* (get cost ride) (var-get platform-fee-percent)) u100))
          (driver-payment (- (get cost ride) fee)))
      
      (try! (as-contract (stx-transfer? driver-payment (get driver ride) tx-sender)))
      (try! (as-contract (stx-transfer? fee contract-owner tx-sender)))
      
      (map-set rides
        { ride-id: ride-id }
        (merge ride { status: "completed" })
      )
      (ok true)
    )
  )
)

(define-public (register-as-driver)
  (map-set drivers
    { driver: tx-sender }
    {
      active: true,
      rating: u0,
      total-rides: u0
    }
  )
  (ok true)
)
