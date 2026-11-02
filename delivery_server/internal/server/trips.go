package server

import (
	"context"
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
)

func bookTrip(w http.ResponseWriter, r *http.Request) {
	type BookTripRequest struct {
		CustomerID    int     `json:"customer_id"`
		TripDistance  int     `json:"trip_distance"`
		TripLatitude  float64 `json:"trip_latitude"`
		TripLongitude float64 `json:"trip_longitude"`
	}

	type BookTripResponseDetail struct {
		TripID        int     `json:"trip_id"`
		CustomerID    int     `json:"customer_id"`
		TripDistance  int     `json:"trip_distance"`
		TripPrice     float64 `json:"trip_price"`
		TripStatusID  int     `json:"trip_status_id"`
		StatusText    string  `json:"status_text"`
		TripLatitude  float64 `json:"trip_latitude"`
		TripLongitude float64 `json:"trip_longitude"`
		Message       string  `json:"message"`
	}
	w.Header().Set("Content-Type", "application/json")

	var req BookTripRequest
	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Dữ liệu JSON không hợp lệ"})
		return
	}

	if req.CustomerID == 0 || req.TripDistance <= 0 || req.TripLatitude == 0 || req.TripLongitude == 0 {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Vui lòng nhập đầy đủ các trường yêu cầu"})
		return
	}

	var pricePerKm int
	priceQuery := "SELECT price_per_km FROM PriceConfig WHERE ? >= `from` AND ? <= `to` LIMIT 1"
	err = db.QueryRow(priceQuery, req.TripDistance, req.TripDistance).Scan(&pricePerKm)

	if err == sql.ErrNoRows {
		pricePerKm = 10000
	} else if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Lỗi hệ thống khi tính toán giá tiền"})
		return
	}

	totalPrice := float64(req.TripDistance * pricePerKm)

	ctx := context.Background()
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Lỗi hệ thống khởi tạo tiến trình"})
		return
	}
	defer tx.Rollback()

	defaultStatusID := 1

	insertTripQuery := `
		INSERT INTO Trip (trip_distance, trip_price, customer_id, driver_id, trip_status_id, trip_latitude, trip_longitude)
		VALUES (?, ?, ?, NULL, ?, ?, ?)
	`
	res, err := tx.ExecContext(ctx, insertTripQuery, req.TripDistance, totalPrice, req.CustomerID, defaultStatusID, req.TripLatitude, req.TripLongitude)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Lỗi hệ thống khi lưu chuyến đi"})
		return
	}

	lastInsertId, _ := res.LastInsertId()
	newTripID := int(lastInsertId)

	updateCustomerLoc := "UPDATE Customer SET latitude = ?, longitude = ? WHERE customer_id = ?"
	_, _ = tx.ExecContext(ctx, updateCustomerLoc, req.TripLatitude, req.TripLongitude, req.CustomerID)

	var statusText string
	statusQuery := "SELECT status FROM TripStatus WHERE trip_status_id = ?"
	err = tx.QueryRowContext(ctx, statusQuery, defaultStatusID).Scan(&statusText)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Lỗi hệ thống khi tra cứu tên trạng thái chuyến đi"})
		return
	}

	if err = tx.Commit(); err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Lỗi hệ thống xác nhận chuyến đi"})
		return
	}

	apiResponse := struct {
		Data BookTripResponseDetail `json:"data"`
	}{
		Data: BookTripResponseDetail{
			TripID:        newTripID,
			CustomerID:    req.CustomerID,
			TripDistance:  req.TripDistance,
			TripPrice:     totalPrice,
			TripStatusID:  defaultStatusID,
			StatusText:    statusText,
			TripLatitude:  req.TripLatitude,
			TripLongitude: req.TripLongitude,
			Message:       "Tạo chuyến đi thành công! Đang tìm kiếm tài xế...",
		},
	}

	jsonData, _ := json.Marshal(apiResponse)
	w.WriteHeader(http.StatusCreated)
	w.Write(jsonData)
}

func cancelTrip(w http.ResponseWriter, r *http.Request) {
}

func reviewDriver(w http.ResponseWriter, r *http.Request) {
	type ReviewTripRequest struct {
		TripID  int    `json:"trip_id"`
		Vote    int    `json:"vote"`
		Comment string `json:"comment"`
	}
	type ReviewResponseDetail struct {
		Message string `json:"message"`
		TripID  int    `json:"trip_id"`
	}
	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(map[string]string{"error": "Phương thức không được hỗ trợ"})
		return
	}

	var req ReviewTripRequest
	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Dữ liệu JSON không hợp lệ"})
		return
	}

	if req.TripID <= 0 || req.Vote < 1 || req.Vote > 5 {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Dữ liệu trip_id hoặc số sao vote (1-5) không hợp lệ"})
		return
	}

	log.Printf("Request review trip ID: %d", req.TripID)

	tx, err := db.Begin()
	if err != nil {
		log.Printf("❌ Lỗi Begin Transaction: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Đã xảy ra lỗi server"})
		return
	}
	defer tx.Rollback()

	var tripStatusID int
	queryCheckTrip := "SELECT trip_status_id FROM Trip WHERE trip_id = ?"
	err = tx.QueryRow(queryCheckTrip, req.TripID).Scan(&tripStatusID)
	if err != nil {
		if err == sql.ErrNoRows {
			w.WriteHeader(http.StatusNotFound)
			json.NewEncoder(w).Encode(map[string]string{"error": "Không tìm thấy chuyến đi này"})
			return
		}
		log.Printf("❌ Lỗi kiểm tra Trip: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Đã xảy ra lỗi server"})
		return
	}

	if tripStatusID != 4 {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Chuyến đi chưa hoàn thành, không thể đánh giá"})
		return
	}

	var existID int
	queryCheckReview := "SELECT reviewId FROM ReviewTrip WHERE trip_id = ? LIMIT 1"
	err = tx.QueryRow(queryCheckReview, req.TripID).Scan(&existID)
	if err != nil && err != sql.ErrNoRows {
		log.Printf("❌ Lỗi kiểm tra Review: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Đã xảy ra lỗi server"})
		return
	}
	if err == nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Chuyến đi này đã được đánh giá trước đó"})
		return
	}

	queryInsert := "INSERT INTO ReviewTrip (comment, vote, trip_id) VALUES (?, ?, ?)"
	_, err = tx.Exec(queryInsert, req.Comment, req.Vote, req.TripID)
	if err != nil {
		log.Printf("❌ Lỗi Insert ReviewTrip: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Không thể lưu đánh giá"})
		return
	}

	if err = tx.Commit(); err != nil {
		log.Printf("❌ Lỗi Commit Transaction: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Đã xảy ra lỗi server"})
		return
	}

	apiResponse := struct {
		Data ReviewResponseDetail `json:"data"`
	}{
		Data: ReviewResponseDetail{
			Message: "Đánh giá chuyến đi thành công!",
			TripID:  req.TripID,
		},
	}

	w.Header().Set("Content-Type", "application/json")
	jsonData, _ := json.Marshal(apiResponse)
	w.WriteHeader(http.StatusOK)
	w.Write(jsonData)
}

func acceptTrip(w http.ResponseWriter, r *http.Request) {
}

func completeTrip(w http.ResponseWriter, r *http.Request) {

}
